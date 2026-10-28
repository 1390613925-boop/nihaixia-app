#!/usr/bin/env python3
"""Fail fast when an upstream merge damages the personal distribution layer."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IDENTITY = ROOT / "lib/config/app_identity.dart"
MANIFEST = ROOT / "tool/protected_assets.sha256"


def fail(message: str) -> None:
    raise SystemExit(f"distribution guard failed: {message}")


def verify_identity() -> None:
    text = IDENTITY.read_text(encoding="utf-8")
    required = (
        "defaultValue: '覓源'",
        "defaultValue: '覓源辨证助手'",
        "defaultValue: '1390613925-boop'",
        "defaultValue: 'nihaixia-app'",
        "packageName = 'com.nihaisha.nihaisha_app'",
    )
    missing = [token for token in required if token not in text]
    if missing:
        fail(f"identity constants changed or missing: {missing}")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(
        encoding="utf-8"
    )
    if 'android:label="覓源"' not in manifest:
        fail("Android application label is not 覓源")

    gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
    if 'applicationId = "com.nihaisha.nihaisha_app"' not in gradle:
        fail("Android package id changed; in-place upgrades would break")


def verify_no_legacy_brand() -> None:
    forbidden = ("汉唐中医", "漢唐中醫", "岐黄经方", "中医大师")
    roots = (ROOT / "lib", ROOT / "android/app/src/main")
    hits: list[str] = []
    for base in roots:
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in {
                ".dart",
                ".kt",
                ".kts",
                ".xml",
                ".java",
            }:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for token in forbidden:
                if token in text:
                    hits.append(f"{path.relative_to(ROOT)}: {token}")
    if hits:
        fail("legacy brand remains in runtime sources:\n  " + "\n  ".join(hits))


def verify_version() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", pubspec, re.M)
    if not match:
        fail("pubspec version must be semantic version + monotonic Android build number")
    if int(match.group(4)) <= 0:
        fail("Android build number must be positive")


def verify_assets() -> None:
    expected: dict[Path, str] = {}
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        digest, relative = line.split(maxsplit=1)
        expected[Path(relative)] = digest.lower()

    actual_json = {
        path.relative_to(ROOT) for path in (ROOT / "assets/data").glob("*.json")
    }
    if actual_json != set(expected):
        added = sorted(str(p) for p in actual_json - set(expected))
        removed = sorted(str(p) for p in set(expected) - actual_json)
        fail(f"protected asset set changed; added={added}, removed={removed}")

    mismatches: list[str] = []
    for relative, wanted in expected.items():
        path = ROOT / relative
        got = hashlib.sha256(path.read_bytes()).hexdigest()
        if got != wanted:
            mismatches.append(f"{relative}: expected {wanted}, got {got}")
    if mismatches:
        fail("protected medical/reference data changed:\n  " + "\n  ".join(mismatches))


def main() -> None:
    verify_identity()
    verify_no_legacy_brand()
    verify_version()
    verify_assets()
    print("distribution guard passed: identity, update feed, package id, version and 15 data assets")


if __name__ == "__main__":
    main()
