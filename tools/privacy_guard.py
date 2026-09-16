"""Reject private material in the working tree and every post-baseline commit.

Standard-library only. Findings identify files and rules, never matched values.
This is a repository hygiene check, not a substitute for reviewing publication.
"""
import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Existing published history is retained. Never advance this value to waive a finding.
HISTORICAL_BASELINE = "603e7ee7b1523df1a30cb48eb67cc353e14d6ea0"

PATH_RULES = (
    ("local environment file", re.compile(r"(?:^|/)\.env(?:\.[^/]*)?$", re.I)),
    ("local runtime or export directory", re.compile(r"(?:^|/)(?:\.venv[^/]*|\.local-history|private|local-data|WTF|SavedVariables|__pycache__)(?:/|$)", re.I)),
    ("runtime output", re.compile(r"(?:^|/)(?:dist)(?:/|$)|\.(?:log|dmp|bak|tmp|pyc)$", re.I)),
    ("design draft", re.compile(r"(?:^|/)(?:mockup(?:-?\d+)?)(?:/|\.|-)|(?:^|/)captures\.json$", re.I)),
    ("private planning document", re.compile(r"(?:^|/)(?:START-HERE|LOGO-PROMPT)\.md$|^docs/curseforge/(?:STATUS\.md|acceptance/)|^docs/curseforge/screenshots/", re.I)),
    ("credential file", re.compile(r"(?:^|/)(?:credentials(?:\.[^/]*)?|id_(?:rsa|ed25519)|.*\.(?:pem|p12|pfx))$", re.I)),
)
CONTENT_RULES = (
    ("personal Windows path", re.compile(rb"[A-Za-z]:[\\/]+(?:Users|Documents and Settings)[\\/]+[^\s\r\n\"'<>]+", re.I)),
    ("personal Unix path", re.compile(rb"/(?:home|Users)/[^/\s\"'<>${}]+/", re.I)),
    ("private workspace reference", re.compile(rb"[H]ourstone-Private|\.codex[\\/]+(?:sessions|visualizations|automations)[\\/]", re.I)),
    ("GitHub credential", re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b")),
    ("service credential", re.compile(rb"\b(?:sk-(?:proj-)?[A-Za-z0-9_-]{24,}|xox[baprs]-[A-Za-z0-9-]{20,}|AKIA[A-Z0-9]{16})\b")),
    ("private key", re.compile(rb"-----BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY-----")),
    ("literal secret assignment", re.compile(rb"\b(?:api[_-]?key|api[_-]?token|cf_api_token|access[_-]?token|client[_-]?secret|password)\s*[=:]\s*[\"'][A-Za-z0-9_+/=.-]{20,}[\"']", re.I)),
)


@dataclass(frozen=True, order=True)
class Finding:
    location: str
    rule: str


def git(root, *args, input=None):
    result = subprocess.run(["git", "-C", str(root), *args], input=input,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        # Git errors can contain local absolute paths; keep public diagnostics neutral.
        raise ValueError("Git inspection failed; ensure complete history and a valid repository")
    return result.stdout


def inspect(path, data, location=None):
    findings = []
    name = path.replace("\\", "/")
    location = location or name
    for rule, pattern in PATH_RULES:
        if pattern.search(name):
            findings.append(Finding(location, rule))
    for rule, pattern in CONTENT_RULES:
        if pattern.search(data):
            findings.append(Finding(location, rule))
    return findings


def current_tree(root):
    findings = []
    paths = git(root, "ls-files", "--cached", "--others", "--exclude-standard", "-z")
    for encoded in sorted(set(paths.split(b"\0")) - {b""}):
        relative = encoded.decode("utf-8", "surrogateescape")
        path = root / relative
        # Removed tracked files are absent from the new tree.
        if not path.exists() and not path.is_symlink():
            continue
        if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):
            findings.append(Finding(relative, "linked file outside ordinary repository contents"))
            continue
        if not path.is_file():
            findings.append(Finding(relative, "unexpected repository entry"))
            continue
        findings.extend(inspect(relative, path.read_bytes()))
    return findings


def introduced_blobs(root, head="HEAD", baseline=HISTORICAL_BASELINE):
    """Inspect every added/changed blob in every commit, including merge parents.

    A final-tree diff alone misses a secret committed and removed before a push.
    Repeated content is deduplicated by blob and path; a renamed blob still gets
    path checks. Deleted entries do not introduce a blob.
    """
    if baseline is not None and not re.fullmatch(r"[0-9a-f]{40,64}", baseline):
        raise ValueError("Historical baseline must be a full commit ID")
    resolution = subprocess.run(["git", "-C", str(root), "rev-parse", "--verify", f"{head}^{{commit}}"],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if resolution.returncode:
        if baseline is None and head == "HEAD" and not git(root, "rev-list", "--all"):
            return []  # An unborn repository still receives current-tree checks.
        raise ValueError("Cannot resolve target commit")
    resolved = resolution.stdout.decode().strip()
    exclusion = []
    if baseline is not None:
        git(root, "cat-file", "-e", f"{baseline}^{{commit}}")
        ancestor = subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", baseline, resolved],
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if ancestor.returncode:
            raise ValueError("Target must descend from the preserved historical baseline")
        exclusion = ["--not", baseline]
    commits = git(root, "rev-list", resolved, *exclusion).decode().splitlines()
    findings, seen = [], set()
    for commit in commits:
        message = git(root, "show", "-s", "--format=%B", commit)
        findings.extend(inspect("commit-message", message, commit[:12] + ":message"))
        entries = git(root, "diff-tree", "--root", "-m", "--no-commit-id", "--raw", "-r", "-z", "--no-renames", commit).split(b"\0")
        for index in range(0, len(entries) - 1, 2):
            metadata, encoded_path = entries[index:index + 2]
            if not metadata:
                continue
            fields = metadata.split()
            if len(fields) != 5:
                raise ValueError("Unexpected Git change record")
            mode, object_id = fields[1], fields[3].decode()
            if set(object_id) == {"0"}:
                continue
            path = encoded_path.decode("utf-8", "surrogateescape")
            if (object_id, path) in seen:
                continue
            seen.add((object_id, path))
            location = commit[:12] + ":" + path
            if mode not in (b"100644", b"100755"):
                findings.append(Finding(location, "linked or non-file Git entry"))
                continue
            findings.extend(inspect(path, git(root, "cat-file", "blob", object_id), location))
    return findings


def pushed_heads(stream):
    heads = []
    for line in stream:
        fields = line.split()
        if len(fields) != 4:
            raise ValueError("Malformed pre-push reference list")
        sha = fields[1]
        if not re.fullmatch(r"[0-9a-f]{40,64}", sha):
            raise ValueError("Malformed pre-push commit ID")
        if set(sha) != {"0"}:
            heads.append(sha)
    return heads


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pre-push", action="store_true", help="Read all pushed references from stdin")
    parser.add_argument("--head", default="HEAD", help="Commit to inspect in CI (default: HEAD)")
    args = parser.parse_args(argv)
    try:
        heads = pushed_heads(sys.stdin) if args.pre_push else [args.head]
        findings = current_tree(ROOT)
        for head in heads:
            findings.extend(introduced_blobs(ROOT, head))
    except (OSError, ValueError) as error:
        print("Privacy check could not complete: " + str(error), file=sys.stderr)
        return 2
    findings = sorted(set(findings))
    if findings:
        print("Privacy check rejected repository contents:", file=sys.stderr)
        for finding in findings:
            print(f"- {finding.location}: {finding.rule}", file=sys.stderr)
        return 1
    print("PASS repository privacy: current files and every new commit checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
