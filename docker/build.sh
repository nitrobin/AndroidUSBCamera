#!/usr/bin/env bash
# Builds the APK inside a container so the result does not depend on --
# or carry traces of -- whatever is installed on the machine running this.
#
#   ./docker/build.sh                      # debug APK
#   ./docker/build.sh :app:assembleRelease  # anything else gradle can do
#
# Result lands in ./output/.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${IMAGE:-androidusbcamera-build}
OUTPUT_DIR=${OUTPUT_DIR:-$REPO_ROOT/output}

echo "==> building image $IMAGE (first run downloads the Android SDK, ~10 min)"
docker build --platform linux/amd64 -t "$IMAGE" "$REPO_ROOT/docker"

mkdir -p "$OUTPUT_DIR"

echo "==> building APK"
docker run --rm \
    --platform linux/amd64 \
    -v "$REPO_ROOT":/src:ro \
    -v "$OUTPUT_DIR":/out \
    -v androidusbcamera-gradle-cache:/root/.gradle \
    "$IMAGE" "${@:-:app:assembleDebug}"

echo
echo "==> done:"
ls -la "$OUTPUT_DIR"
