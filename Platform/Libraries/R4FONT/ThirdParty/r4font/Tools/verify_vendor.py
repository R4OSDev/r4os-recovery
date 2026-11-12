#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 R4OS contributors

"""Write or verify the complete checked-in R4FONT vendor byte manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve()
ROOT = SCRIPT_PATH.parent.parent
MANIFEST_PATH = ROOT / "VENDOR.sha256"
UPSTREAM_PATH = ROOT / "UPSTREAM.json"
TRACKED_DIRECTORIES = (
    "brotli",
    "config",
    "freestanding",
    "freetype",
    "include",
    "Patches",
    "src",
)
TRACKED_FILES = ("ZLIB-LICENSE",)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tracked_paths() -> list[Path]:
    paths: list[Path] = []
    for directory in TRACKED_DIRECTORIES:
        paths.extend(path for path in (ROOT / directory).rglob("*") if path.is_file())
    paths.extend(ROOT / name for name in TRACKED_FILES)
    return sorted(paths, key=lambda path: path.relative_to(ROOT).as_posix())


def generated_manifest() -> bytes:
    lines = [
        f"{sha256(path)}  {path.relative_to(ROOT).as_posix()}\n"
        for path in tracked_paths()
    ]
    return "".join(lines).encode("ascii")


def metadata() -> dict[str, object]:
    return json.loads(UPSTREAM_PATH.read_text(encoding="utf-8"))


def reverse_unified_patch(patched: bytes, patch_text: str) -> bytes:
    current = patched.decode("utf-8").splitlines(keepends=True)
    patch_lines = patch_text.splitlines(keepends=True)
    output: list[str] = []
    cursor = 0
    index = 0
    hunk_count = 0
    hunk_pattern = re.compile(
        r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"
    )
    while index < len(patch_lines):
        match = hunk_pattern.match(patch_lines[index])
        if not match:
            index += 1
            continue
        hunk_count += 1
        old_count = int(match.group(2) or "1")
        new_start = int(match.group(3))
        new_count = int(match.group(4) or "1")
        new_cursor = new_start - 1
        if new_cursor < cursor or new_cursor > len(current):
            raise ValueError("patch hunk starts outside the patched target")
        output.extend(current[cursor:new_cursor])
        cursor = new_cursor
        index += 1
        seen_old = 0
        seen_new = 0
        while index < len(patch_lines) and not patch_lines[index].startswith("@@ "):
            line = patch_lines[index]
            if line.startswith(("diff --git ", "--- ", "+++ ")):
                break
            if line.startswith(" "):
                content = line[1:]
                if cursor >= len(current) or current[cursor] != content:
                    actual = current[cursor] if cursor < len(current) else "<eof>"
                    raise ValueError(
                        f"patch context differs at target line {cursor + 1}: "
                        f"expected={content!r} actual={actual!r}"
                    )
                output.append(content)
                cursor += 1
                seen_old += 1
                seen_new += 1
            elif line.startswith("+"):
                content = line[1:]
                if cursor >= len(current) or current[cursor] != content:
                    actual = current[cursor] if cursor < len(current) else "<eof>"
                    raise ValueError(
                        f"patch addition differs at target line {cursor + 1}: "
                        f"expected={content!r} actual={actual!r}"
                    )
                cursor += 1
                seen_new += 1
            elif line.startswith("-"):
                output.append(line[1:])
                seen_old += 1
            elif line.startswith("\\ No newline at end of file"):
                raise ValueError("no-newline patches are not supported")
            index += 1
        if seen_old != old_count or seen_new != new_count:
            raise ValueError("patch hunk line counts are inconsistent")
    if hunk_count == 0:
        raise ValueError("patch contains no unified hunks")
    output.extend(current[cursor:])
    return "".join(output).encode("utf-8")


def check_declared_hashes(document: dict[str, object]) -> list[str]:
    errors: list[str] = []
    declared_manifest = document["verification"]["file_manifest_sha256"]
    actual_manifest = sha256(MANIFEST_PATH)
    if declared_manifest != actual_manifest:
        errors.append(f"VENDOR.sha256 hash mismatch: {actual_manifest}")
    manifest_lines = MANIFEST_PATH.read_text(encoding="ascii").splitlines()
    if len(manifest_lines) != document["verification"]["tracked_file_count"]:
        errors.append("tracked file count differs from VENDOR.sha256")
    declared_script = document["verification"]["check_script_sha256"]
    actual_script = sha256(SCRIPT_PATH)
    if declared_script != actual_script:
        errors.append(f"verify_vendor.py hash mismatch: {actual_script}")

    for component_name in ("freetype", "brotli", "zlib"):
        component = document[component_name]
        version_path = ROOT / component["version_file"]
        if not version_path.is_file():
            errors.append(f"missing {component_name} version file")
        else:
            version_text = version_path.read_text(encoding="utf-8")
            for marker in component["version_markers"]:
                if marker not in version_text:
                    errors.append(
                        f"{component_name} {component['version']} marker missing: {marker}"
                    )
        license_files = component.get("license_files", {})
        if "license_file" in component:
            license_files = {
                component["license_file"]: component["license_file_sha256"]
            }
        for relative, expected in license_files.items():
            license_path = ROOT / relative
            if not license_path.is_file():
                errors.append(f"missing {component_name} license: {relative}")
            elif sha256(license_path) != expected:
                errors.append(f"{component_name} license hash mismatch: {relative}")

    for patch in document["freetype"]["local_patches"]:
        target = ROOT / "freetype" / patch["target"]
        patch_path = ROOT / patch["patch"]
        if not target.is_file() or sha256(target) != patch["patched_sha256"]:
            errors.append(f"patched target mismatch: {patch['target']}")
        if not patch_path.is_file() or sha256(patch_path) != patch["patch_sha256"]:
            errors.append(f"patch artifact mismatch: {patch['patch']}")
        patch_text = patch_path.read_text(encoding="utf-8") if patch_path.is_file() else ""
        expected_header = f"+++ b/{patch['target']}"
        if expected_header not in patch_text:
            errors.append(f"patch target header mismatch: {patch['patch']}")
        elif target.is_file():
            try:
                upstream = reverse_unified_patch(target.read_bytes(), patch_text)
                if hashlib.sha256(upstream).hexdigest() != patch["upstream_sha256"]:
                    errors.append(f"patch preimage mismatch: {patch['patch']}")
            except (UnicodeDecodeError, ValueError) as error:
                errors.append(f"patch replay failed: {patch['patch']}: {error}")
    return errors


def check() -> int:
    expected = generated_manifest()
    actual = MANIFEST_PATH.read_bytes() if MANIFEST_PATH.is_file() else b""
    errors: list[str] = []
    if actual != expected:
        errors.append("VENDOR.sha256 does not match the checked-in vendor tree")
    try:
        errors.extend(check_declared_hashes(metadata()))
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        errors.append(f"invalid UPSTREAM.json verification contract: {error}")
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print(
        f"R4FONT vendor check passed: {len(tracked_paths())} files, "
        "licenses and local patches are byte-pinned."
    )
    return 0


def write() -> int:
    content = generated_manifest()
    MANIFEST_PATH.write_bytes(content)
    print(
        f"wrote {MANIFEST_PATH} files={len(tracked_paths())} "
        f"sha256={hashlib.sha256(content).hexdigest()}"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    args = parser.parse_args()
    return check() if args.check else write()


if __name__ == "__main__":
    raise SystemExit(main())
