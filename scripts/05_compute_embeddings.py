#!/usr/bin/env python3
"""
Placeholder for embedding generation.
Will be implemented after minimal milestone sign-off.
"""

from pathlib import Path


def main() -> None:
    Path("data/interim/embeddings").mkdir(parents=True, exist_ok=True)
    print("Embedding stage not run in minimal milestone.")


if __name__ == "__main__":
    main()
