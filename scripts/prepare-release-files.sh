#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  cat <<'EOF' >&2
Usage: ./scripts/prepare-release-files.sh <release-dir> <bundle-path> <web-dir> [template-path]
EOF
  exit 1
fi

RELEASE_DIR="$1"
BUNDLE_PATH="$2"
WEB_DIR="$3"
TEMPLATE_PATH="${4:-}"

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
PACKAGE_ROOT="${RELEASE_DIR}/yt-sub-linux-amd64"

rm -rf "$PACKAGE_ROOT"
mkdir -p "$PACKAGE_ROOT/backend" "$PACKAGE_ROOT/frontend" "$PACKAGE_ROOT/scripts"

cp "$REPO_ROOT/LICENSE" "$PACKAGE_ROOT/LICENSE"
cp "$BUNDLE_PATH" "$PACKAGE_ROOT/backend/sub-store.bundle.js"
cp -R "$WEB_DIR/." "$PACKAGE_ROOT/frontend/"
cp "$REPO_ROOT/scripts/container-init.sh" "$PACKAGE_ROOT/scripts/container-init.sh"
cp "$REPO_ROOT/scripts/ct-entrypoint.sh" "$PACKAGE_ROOT/scripts/ct-entrypoint.sh"
cp "$REPO_ROOT/Dockerfile" "$PACKAGE_ROOT/Dockerfile"

if [[ -n "$TEMPLATE_PATH" && -f "$TEMPLATE_PATH" ]]; then
  cp "$TEMPLATE_PATH" "$PACKAGE_ROOT/$(basename "$TEMPLATE_PATH")"
fi

tar -C "$RELEASE_DIR" -czf "${RELEASE_DIR}/yt-sub-linux-amd64.tar.gz" yt-sub-linux-amd64
