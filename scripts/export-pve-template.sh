#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat <<'EOF' >&2
Usage: ./scripts/export-pve-template.sh <docker-image> <output-template.tar.zst>
EOF
  exit 1
fi

if ! command -v zstd >/dev/null 2>&1; then
  echo "zstd is required" >&2
  exit 1
fi

if [[ -n "${CONTAINER_RUNTIME:-}" ]]; then
  RUNTIME_BIN="$CONTAINER_RUNTIME"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME_BIN="docker"
elif command -v podman >/dev/null 2>&1; then
  RUNTIME_BIN="podman"
else
  echo "docker or podman is required" >&2
  exit 1
fi

IMAGE_NAME="$1"
OUTPUT_PATH="$2"

mkdir -p "$(dirname "$OUTPUT_PATH")"

cid=$("$RUNTIME_BIN" create "$IMAGE_NAME")
trap '"$RUNTIME_BIN" rm -f "$cid" >/dev/null 2>&1 || true' EXIT

"$RUNTIME_BIN" export "$cid" | zstd -19 -T0 -o "$OUTPUT_PATH" -f
