#!/bin/sh
# Build the patched AionUi web tarball for an upstream tag and attach it to a
# release of this repo. Then bump AIONUI_VERSION/AIONUI_SHA256 in ../Dockerfile.
#   build/release.sh 2.2.2
set -e
V=${1:?usage: build/release.sh <upstream version, e.g. 2.2.2>}
cd "$(dirname "$0")/.."
docker build -f build/Dockerfile --build-arg AIONUI_REF="v$V" -t aionui-build .
T="dist/aionui-web-$V-railway-linux-x86_64.tar.gz"
mkdir -p dist
id=$(docker create aionui-build)
docker cp "$id:/src/dist-web-cli/aionui-web-$V-linux-x86_64.tar.gz" "$T"
docker rm "$id" >/dev/null
gh release create "v$V" "$T" --title "AionUi WebUI $V for Railway" \
  --notes "Upstream AionUi v$V web build (linux x64) with build/remote-auth.patch applied."
echo "AIONUI_VERSION=$V AIONUI_SHA256=$(sha256sum "$T" | cut -d' ' -f1)"
