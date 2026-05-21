#!/usr/bin/env python3
"""Download and locally mirror Curiosity Dialogs files with integrity checks."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fetch Curiosity Dialogs files from the canonical media URL."
    )
    parser.add_argument(
        "--manifest",
        default="data/curiosity/manifest.json",
        help="Path to manifest JSON file.",
    )
    parser.add_argument(
        "--data-dir",
        default=None,
        help="Local output directory (default from CURIOSITY_DATA_DIR or manifest).",
    )
    parser.add_argument(
        "--include-optional",
        action="store_true",
        help="Also download optional large auxiliary files.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Always re-download files even if local checks pass.",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=4,
        help="Retries per file on transient failures.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="HTTP timeout in seconds.",
    )
    return parser.parse_args()


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        manifest = json.load(f)
    required_keys = {"base_url", "default_data_dir", "files"}
    missing = required_keys - set(manifest.keys())
    if missing:
        raise ValueError(f"Manifest is missing required keys: {sorted(missing)}")
    return manifest


def compute_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_local_file_valid(path: Path, expected_size: int, expected_sha256: str) -> bool:
    if not path.exists():
        return False
    if path.stat().st_size != expected_size:
        return False
    return compute_sha256(path) == expected_sha256


def download_with_retries(url: str, destination: Path, retries: int, timeout: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "wb", delete=False, dir=str(destination.parent), prefix=destination.name + ".tmp."
    ) as tmp_file:
        tmp_path = Path(tmp_file.name)
    try:
        command = [
            "curl",
            "-fL",
            "--retry",
            str(retries),
            "--retry-all-errors",
            "--connect-timeout",
            str(timeout),
            "--max-time",
            str(max(timeout * 20, 300)),
            "--output",
            str(tmp_path),
            url,
        ]
        result = subprocess.run(command, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            stderr = result.stderr.strip()
            raise RuntimeError(
                f"curl failed (exit {result.returncode}) for {url}: {stderr}"
            )
        os.replace(tmp_path, destination)
    except Exception:
        if tmp_path.exists():
            tmp_path.unlink()
        raise


def main() -> int:
    args = parse_args()
    manifest_path = Path(args.manifest)
    manifest = load_manifest(manifest_path)

    data_dir = Path(
        args.data_dir
        or os.environ.get("CURIOSITY_DATA_DIR")
        or manifest["default_data_dir"]
    )
    base_url: str = manifest["base_url"].rstrip("/")

    files: list[dict[str, Any]] = manifest["files"]
    selected = [f for f in files if args.include_optional or f.get("required", False)]

    if not selected:
        print("No files selected for download.")
        return 0

    print(f"Manifest: {manifest_path}")
    print(f"Output dir: {data_dir}")
    print(f"Selected files: {len(selected)}")

    failures: list[str] = []
    for entry in selected:
        name = entry["name"]
        expected_size = int(entry["size_bytes"])
        expected_sha256 = str(entry["sha256"])
        url = f"{base_url}/{name}"
        output_path = data_dir / name

        print(f"\n{name}")
        if not args.force and is_local_file_valid(output_path, expected_size, expected_sha256):
            print("  already valid, skipping")
            continue

        print(f"  downloading from {url}")
        try:
            download_with_retries(url, output_path, retries=args.retries, timeout=args.timeout)
            actual_size = output_path.stat().st_size
            actual_sha = compute_sha256(output_path)
            if actual_size != expected_size:
                raise RuntimeError(
                    f"size mismatch: expected {expected_size}, got {actual_size}"
                )
            if actual_sha != expected_sha256:
                raise RuntimeError(
                    f"sha256 mismatch: expected {expected_sha256}, got {actual_sha}"
                )
            print("  downloaded and verified")
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{name}: {exc}")
            print(f"  FAILED: {exc}")

    if failures:
        print("\nDownload finished with failures:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("\nDownload finished successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
