#!/usr/bin/env bash
set -euo pipefail

APP_NAME="zoltd"
SRC_FILE="main.go"
BUILD_DIR="dist"

PLATFORMS=(
    "darwin/amd64"
    "darwin/arm64"
    "linux/amd64"
    "linux/arm64"
    "windows/amd64"
    "windows/arm64"
)

mkdir -p "$BUILD_DIR"

echo "Building $SRC_FILE..."

for platform in "${PLATFORMS[@]}"; do
    IFS="/" read -r GOOS GOARCH <<< "$platform"

    output_name="${APP_NAME}-${GOOS}-${GOARCH}"

    if [ "$GOOS" = "windows" ]; then
        output_name+=".exe"
    fi

    echo "Compiling: GOOS=$GOOS GOARCH=$GOARCH..."

    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/${output_name}" \
        "$SRC_FILE"
done

echo "Build process complete. Binaries generated in ./${BUILD_DIR}/"
