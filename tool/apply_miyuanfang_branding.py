#!/usr/bin/env python3
"""Reapply the personal Miyuanfang branding after merging upstream."""

from pathlib import Path


TARGETS = (
    Path("pubspec.yaml"),
    Path("android/app/src/main/AndroidManifest.xml"),
    Path("lib/main.dart"),
    Path("lib/engine/diagnostic_engine.dart"),
    Path("lib/screens/activation_screen.dart"),
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
        branded = text.replace("汉唐中医", "覓源方").replace("岐黄经方", "覓源方")
        if branded != text:
            path.write_text(branded, encoding="utf-8")
            changed.append(str(path))

    residual = [
        str(path)
        for path in TARGETS
        if any(name in path.read_text(encoding="utf-8") for name in ("汉唐中医", "岐黄经方"))
    ]
    if residual:
        raise SystemExit(f"Branding residual remains: {', '.join(residual)}")

    print("Miyuanfang branding verified.")
    if changed:
        print("Updated: " + ", ".join(changed))


if __name__ == "__main__":
    main()

