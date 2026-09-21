#!/usr/bin/env bash
# Copies the source tree out of the read-only mount, builds it, and drops
# the resulting APKs into /out.
#
# The copy is deliberate: building straight in the mount would write the
# container's SDK path into the host's local.properties, and would leak
# host paths into the native debug info. Everything here happens under
# /workspace, so nothing in the artifacts points back at the build machine.
set -euo pipefail

SRC=${SRC:-/src}
WORK=/workspace
OUT=${OUT:-/out}

if [ ! -d "$SRC" ]; then
    echo "error: source tree not mounted at $SRC" >&2
    exit 1
fi

rsync -a --delete \
    --exclude '.git/' \
    --exclude 'build/' \
    --exclude '.gradle/' \
    --exclude 'local.properties' \
    --exclude '*.apk' \
    "$SRC"/ "$WORK"/

cd "$WORK"
{
    echo "sdk.dir=$ANDROID_SDK_ROOT"
    echo "ndk.dir=$NDK_HOME"
} > local.properties
chmod +x gradlew

./gradlew --no-daemon "$@"

mkdir -p "$OUT"
find "$WORK" -path '*/outputs/apk/*' -name '*.apk' -print -exec cp {} "$OUT"/ \;
echo "APKs copied to $OUT"
