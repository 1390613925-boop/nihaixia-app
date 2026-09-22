#!/usr/bin/env python3
"""Reapply the personal Qihuang branding after merging upstream."""

from pathlib import Path


TARGETS = (
    Path("pubspec.yaml"),
    Path("lib/engine/diagnostic_engine.dart"),
    Path("lib/screens/chat_screen.dart"),
    Path("lib/screens/app_dialogs.dart"),
    Path("lib/screens/bazi_paipan_screen.dart"),
    Path("lib/data/medical_case_data.dart"),
    Path("test/engine/diagnostic_engine_test.dart"),
)


def main() -> None:
    missing = [str(path) for path in TARGETS if not path.is_file()]
    if missing:
        raise SystemExit(f"Branding target missing: {', '.join(missing)}")

    changed = []
    for path in TARGETS:
        text = path.read_text(encoding="utf-8")
        branded = text.replace("汉唐中医", "岐黄经方")
        if branded != text:
            path.write_text(branded, encoding="utf-8")
            changed.append(str(path))

    residual = [
        str(path)
        for path in TARGETS
        if "汉唐中医" in path.read_text(encoding="utf-8")
    ]
    if residual:
        raise SystemExit(f"Branding residual remains: {', '.join(residual)}")

    print("Qihuang branding verified.")
    if changed:
        print("Updated: " + ", ".join(changed))


if __name__ == "__main__":
    main()
