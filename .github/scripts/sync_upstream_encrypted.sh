#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_URL="https://github.com/jangviktor-web/nihaixia-app.git"
PROTECTED_FILE=".github/customization-protected-paths.txt"
SNAPSHOT_DIR="$(mktemp -d)"
trap 'rm -rf "$SNAPSHOT_DIR"' EXIT

# Keep the personal build number as a lower bound even if upstream carries an
# older version string.
grep -E '^version:' pubspec.yaml | awk '{print $2}' > "$SNAPSHOT_DIR/previous-version.txt"

git remote remove upstream 2>/dev/null || true
git remote add upstream "$UPSTREAM_URL"
git fetch --no-tags upstream master

if git merge-base --is-ancestor upstream/master HEAD; then
  echo "UPSTREAM_CHANGED=false" >> "$GITHUB_OUTPUT"
  echo "The personal repository already contains the latest upstream commit."
  exit 0
fi

mapfile -t protected_paths < <(grep -Ev '^[[:space:]]*(#|$)' "$PROTECTED_FILE")
for path in "${protected_paths[@]}"; do
  if [ -e "$path" ]; then
    mkdir -p "$SNAPSHOT_DIR/$(dirname "$path")"
    cp -a "$path" "$SNAPSHOT_DIR/$path"
  fi
done

# Merge all ordinary upstream changes. Conflicts default to upstream, after
# which the explicitly listed private-distribution paths are restored.
git merge --no-edit -X theirs upstream/master

for path in "${protected_paths[@]}"; do
  if [ -e "$SNAPSHOT_DIR/$path" ]; then
    rm -rf "$path"
    mkdir -p "$(dirname "$path")"
    cp -a "$SNAPSHOT_DIR/$path" "$path"
  fi
done

# Android requires a larger versionCode for an in-place update. Both values are
# incremented automatically; no manual version editing is needed.
PREVIOUS_VERSION="$(cat "$SNAPSHOT_DIR/previous-version.txt")" python3 <<'PY'
from pathlib import Path
import os
import re

pubspec = Path("pubspec.yaml")
text = pubspec.read_text(encoding="utf-8")
m = re.search(r"(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", text)
if not m:
    raise SystemExit("pubspec.yaml version must be MAJOR.MINOR.PATCH+BUILD")
merged = tuple(map(int, m.groups()))
previous_match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)\+(\d+)", os.environ["PREVIOUS_VERSION"])
if not previous_match:
    raise SystemExit("previous pubspec version must be MAJOR.MINOR.PATCH+BUILD")
previous = tuple(map(int, previous_match.groups()))
base_semver = max(merged[:3], previous[:3])
major, minor, patch = base_semver
build = max(merged[3], previous[3]) + 1
version = f"{major}.{minor}.{patch + 1}+{build}"
text = text[:m.start()] + f"version: {version}" + text[m.end():]
pubspec.write_text(text, encoding="utf-8")
Path(".github/next-version.txt").write_text(version, encoding="utf-8")
PY

version="$(cat .github/next-version.txt)"
rm .github/next-version.txt
tag="v${version%%+*}"
mkdir -p release_notes
cat > "release_notes/$tag.md" <<EOF
# 岐黄经方 $tag

- 同步上游仓库最新代码与数据。
- 保留离线设备卡密、岐黄经方名称与图标。
- 更新检查继续使用 1390613925-boop/nihaixia-app。
- 使用既有正式证书签名，并启用 R8 混淆与资源收缩。
EOF

echo "UPSTREAM_CHANGED=true" >> "$GITHUB_OUTPUT"
echo "VERSION=$version" >> "$GITHUB_OUTPUT"
echo "TAG=$tag" >> "$GITHUB_OUTPUT"
