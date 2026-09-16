"""Enable the repository's versioned pre-push hook for this local checkout."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

if __name__ == "__main__":
    subprocess.run(["git", "-C", str(ROOT), "config", "--local", "core.hooksPath", ".githooks"], check=True)
    print("Enabled .githooks/pre-push for this checkout.")
