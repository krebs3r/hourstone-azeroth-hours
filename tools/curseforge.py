"""Upload the exact GitHub release ZIP using the CurseForge Upload API.

A persistent GitHub release asset locks each upload BEFORE the POST. A receipt
makes successful reruns a no-op. Ambiguous attempts require dashboard inspection.
No third-party dependencies; the GitHub CLI is available on Actions runners.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
API = "https://wow.curseforge.com/api"
PENDING = "curseforge-upload-pending.json"
RECEIPT = "curseforge-upload.json"


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def api_request(path, token, data=None, content_type=None):
    headers = {"X-Api-Token": token, "Accept": "application/json"}
    if content_type:
        headers["Content-Type"] = content_type
    request = Request(API + path, headers=headers, data=data)
    try:
        # Never forward the credential to a redirected host; never retry a POST.
        with build_opener(NoRedirects()).open(request, timeout=120) as response:
            return json.load(response)
    except HTTPError as exc:
        raise RuntimeError(f"CurseForge API returned HTTP {exc.code}; check the authors dashboard before retrying an upload.") from None
    except (URLError, TimeoutError, OSError, ValueError) as exc:
        raise RuntimeError("CurseForge response unavailable or invalid; check the authors dashboard before retrying an upload.") from None


def resolve_versions(available, names):
    if not names or len(set(names)) != len(names):
        raise ValueError("Configure a nonempty, unique game_versions list in project.json")
    ids = []
    for name in names:
        matches = [v["id"] for v in available if v.get("name") == name]
        if len(matches) != 1 or type(matches[0]) is not int or matches[0] <= 0:
            raise ValueError(f"CurseForge game version {name!r} is missing or ambiguous")
        ids.append(matches[0])
    return ids


def gh(*args):
    result = subprocess.run(["gh", *args], check=True, capture_output=True, text=True, encoding="utf-8")
    return result.stdout


def verify_package(archive, checksum, tag, assets):
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    parts = checksum.read_text(encoding="ascii").split()
    if parts != [digest, archive.name]:
        raise ValueError("Release ZIP does not match its SHA-256 file")
    asset = next(a for a in assets if a["name"] == archive.name)
    if asset.get("digest") != f"sha256:{digest}":
        raise ValueError("Release ZIP does not match GitHub's asset digest")
    with zipfile.ZipFile(archive) as package:
        if package.testzip() or any(not n.startswith("Hourstone/") or ".." in Path(n).parts for n in package.namelist()):
            raise ValueError("Invalid install ZIP structure")
        toc = package.read("Hourstone/Hourstone.toc").decode("utf-8")
        if not re.search(rf"^## Version: {re.escape(tag[1:])}\r?$", toc, re.M):
            raise ValueError("Release tag does not match the ZIP's TOC version")
    return digest


def validate_receipt(receipt, tag, project_id, digest):
    if (receipt.get("tag") != tag or receipt.get("project_id") != project_id
            or receipt.get("sha256") != digest
            or type(receipt.get("file_id")) is not int or receipt["file_id"] <= 0):
        raise ValueError("Existing CurseForge receipt does not match this release")
    return receipt["file_id"]


def multipart(metadata, archive):
    boundary = "hourstone-" + uuid.uuid4().hex
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n'
        'Content-Type: application/json\r\n\r\n'
    ).encode() + json.dumps(metadata).encode("utf-8")
    body += (
        f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{archive.name}"\r\n'
        'Content-Type: application/zip\r\n\r\n'
    ).encode() + archive.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    return body, f"multipart/form-data; boundary={boundary}"


def write_record(path, record):
    path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")


def report(file_id, message):
    url = f"https://www.curseforge.com/wow/addons/hourstone-azeroth-hours/files/{file_id}"
    print(f"{message}: {url}")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
            summary.write(f"### CurseForge\n{message}: [file {file_id}]({url}).\n\nPublication follows CurseForge approval.\n")


def publish(tag, config, root=ROOT):
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        raise ValueError("Expected a stable version tag such as v0.1.2")
    work = root / "dist/curseforge"
    work.mkdir(parents=True, exist_ok=True)
    release = json.loads(gh("release", "view", tag, "--json", "assets,body,isDraft,isPrerelease"))
    if release["isDraft"] or release["isPrerelease"]:
        raise ValueError("Only published stable GitHub releases may be uploaded")
    names = {a["name"] for a in release["assets"]}
    archive = work / f"Hourstone-{tag[1:]}.zip"
    checksum = archive.with_suffix(".zip.sha256")
    for path in (archive, checksum):
        if path.name not in names:
            raise ValueError(f"Missing GitHub release asset: {path.name}")
        gh("release", "download", tag, "--pattern", path.name, "--dir", str(work), "--clobber")
    digest = verify_package(archive, checksum, tag, release["assets"])
    # Honor both automated receipts and the recorded first manual upload.
    historical = root / "docs/curseforge/releases" / f"{tag}.json"
    if RECEIPT in names:
        gh("release", "download", tag, "--pattern", RECEIPT, "--dir", str(work), "--clobber")
        receipt = json.loads((work / RECEIPT).read_text(encoding="utf-8"))
    elif historical.is_file():
        receipt = json.loads(historical.read_text(encoding="utf-8"))
    else:
        receipt = None
    if receipt is not None:
        file_id = validate_receipt(receipt, tag, config["project_id"], digest)
        report(file_id, "Already uploaded; no duplicate submitted")
        return
    if PENDING in names:
        raise RuntimeError("An earlier upload may have reached CurseForge. Inspect the authors dashboard and restore its receipt before retrying; see docs/curseforge/README.md.")
    if not release["body"].strip():
        raise ValueError("GitHub release notes must not be empty")
    token = require_token()
    versions = resolve_versions(api_request("/game/versions", token), config["game_versions"])
    metadata = {
        "changelog": release["body"], "changelogType": "markdown",
        "displayName": f"Hourstone {tag[1:]}", "releaseType": "release",
        "gameVersions": versions, "isMarkedForManualRelease": False,
    }
    body, content_type = multipart(metadata, archive)
    record = {
        "tag": tag, "project_id": config["project_id"], "sha256": digest,
        "file_name": archive.name, "game_versions": config["game_versions"],
        "game_version_ids": versions, "status": "upload-pending",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "run_id": os.environ.get("GITHUB_RUN_ID"),
    }
    write_record(work / PENDING, record)
    # No --clobber: the asset's unique name is a durable per-release lock.
    gh("release", "upload", tag, str(work / PENDING))
    result = api_request(f'/projects/{config["project_id"]}/upload-file', token, body, content_type)
    if not isinstance(result, dict) or type(result.get("id")) is not int or result["id"] <= 0:
        raise RuntimeError("Upload response has no valid file ID. Inspect CurseForge before retrying.")
    record.update(file_id=result["id"], status="uploaded-awaiting-approval")
    write_record(work / RECEIPT, record)
    gh("release", "upload", tag, str(work / RECEIPT))
    report(result["id"], "Uploaded successfully")


def require_token():
    token = os.environ.get("CF_API_TOKEN", "").strip()
    if not token:
        raise ValueError("Missing GitHub Actions repository secret CF_API_TOKEN; see docs/curseforge/README.md")
    return token


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--tag")
    mode.add_argument("--check", action="store_true", help="Read-only token and game-version check; never uploads")
    args = parser.parse_args()
    config = json.loads((ROOT / "docs/curseforge/project.json").read_text(encoding="utf-8"))
    if args.check:
        ids = resolve_versions(api_request("/game/versions", require_token()), config["game_versions"])
        print(f'CurseForge token accepted. Configured versions: {list(zip(config["game_versions"], ids))}. No file uploaded.')
    else:
        publish(args.tag, config)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, subprocess.CalledProcessError, OSError, KeyError, zipfile.BadZipFile) as error:
        # Do not print response bodies or credentials.
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
