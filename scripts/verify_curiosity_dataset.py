#!/usr/bin/env python3
"""Verify Curiosity Dialogs remote reachability and local mirror integrity."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify Curiosity Dialogs remote and local dataset access."
    )
    parser.add_argument(
        "--manifest",
        default="data/curiosity/manifest.json",
        help="Path to manifest JSON file.",
    )
    parser.add_argument(
        "--data-dir",
        default=None,
        help="Local data directory (default from CURIOSITY_DATA_DIR or manifest).",
    )
    parser.add_argument(
        "--include-optional",
        action="store_true",
        help="Verify optional auxiliary files in addition to required split files.",
    )
    parser.add_argument(
        "--skip-remote",
        action="store_true",
        help="Skip remote HEAD checks.",
    )
    parser.add_argument(
        "--skip-local",
        action="store_true",
        help="Skip local file checks.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="HTTP timeout in seconds for remote checks.",
    )
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def sha256_of_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_remote(url: str, timeout: int) -> tuple[bool, str]:
    command = [
        "curl",
        "-sI",
        "--connect-timeout",
        str(timeout),
        "--max-time",
        str(max(timeout * 5, 60)),
        "-o",
        "/dev/null",
        "-w",
        "%{http_code}",
        url,
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            stderr = result.stderr.strip()
            return False, f"curl exit {result.returncode}: {stderr}"
        status = result.stdout.strip()
        if status == "200":
            return True, "HTTP 200"
        return False, f"HTTP {status}"
    except Exception as exc:  # noqa: BLE001
        return False, f"{type(exc).__name__}: {exc}"


def smoke_check_json(path: Path) -> tuple[bool, str]:
    try:
        with path.open("r", encoding="utf-8") as f:
            payload = json.load(f)
        dialogs = payload.get("dialogs")
        if not isinstance(dialogs, list):
            return False, "missing or invalid top-level dialogs field"
        if len(dialogs) == 0:
            return False, "dialogs list is empty"
        return True, f"dialogs_count={len(dialogs)}"
    except json.JSONDecodeError as exc:
        return False, f"invalid JSON: {exc}"
    except Exception as exc:  # noqa: BLE001
        return False, f"{type(exc).__name__}: {exc}"


def main() -> int:
    args = parse_args()
    manifest = load_manifest(Path(args.manifest))
    base_url = str(manifest["base_url"]).rstrip("/")
    data_dir = Path(
        args.data_dir
        or os.environ.get("CURIOSITY_DATA_DIR")
        or manifest["default_data_dir"]
    )

    files: list[dict[str, Any]] = manifest["files"]
    selected = [f for f in files if args.include_optional or f.get("required", False)]

    failures: list[str] = []

    print(f"Manifest: {args.manifest}")
    print(f"Data dir: {data_dir}")
    print(f"Selected files: {len(selected)}")

    for entry in selected:
        name = entry["name"]
        expected_size = int(entry["size_bytes"])
        expected_sha = str(entry["sha256"])
        url = f"{base_url}/{name}"
        local_path = data_dir / name

        print(f"\n{name}")
        if not args.skip_remote:
            ok, msg = check_remote(url, timeout=args.timeout)
            print(f"  remote: {msg}")
            if not ok:
                failures.append(f"{name} remote check failed: {msg}")

        if not args.skip_local:
            if not local_path.exists():
                msg = f"missing local file: {local_path}"
                print(f"  local: {msg}")
                failures.append(f"{name} {msg}")
                continue

            actual_size = local_path.stat().st_size
            if actual_size != expected_size:
                msg = f"size mismatch expected={expected_size} actual={actual_size}"
                print(f"  local: {msg}")
                failures.append(f"{name} {msg}")
                continue

            actual_sha = sha256_of_file(local_path)
            if actual_sha != expected_sha:
                msg = "sha256 mismatch"
                print(f"  local: {msg}")
                failures.append(f"{name} {msg}")
                continue

            print("  local: size and sha256 verified")

            if name.endswith(".json") and name.startswith("curiosity_dialogs"):
                ok, smoke_msg = smoke_check_json(local_path)
                print(f"  smoke: {smoke_msg}")
                if not ok:
                    failures.append(f"{name} smoke check failed: {smoke_msg}")

    if failures:
        print("\nVerification FAILED:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("\nVerification PASSED.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
