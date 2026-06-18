#!/usr/bin/env bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

export TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX:-aarch64-linux-gnu}"
export HOST="${HOST:-aarch64-linux-gnu}"
export BUILD_PREFIX="${BUILD_PREFIX:-${PWD}/prefix}"

# ── Build libzmq ───────────────────────────────────────────────
echo "=== Building libzmq for ${HOST} ==="

rm -rf "${BUILD_PREFIX}"
mkdir -p "${BUILD_PREFIX}"

CONFIG_OPTS=()
CONFIG_OPTS+=("--host=${HOST}")
CONFIG_OPTS+=("--prefix=${BUILD_PREFIX}")
CONFIG_OPTS+=("CC=${TOOLCHAIN_PREFIX}-gcc")
CONFIG_OPTS+=("CXX=${TOOLCHAIN_PREFIX}-g++")
CONFIG_OPTS+=("AR=${TOOLCHAIN_PREFIX}-ar")
CONFIG_OPTS+=("RANLIB=${TOOLCHAIN_PREFIX}-ranlib")
CONFIG_OPTS+=("LD=${TOOLCHAIN_PREFIX}-ld")
CONFIG_OPTS+=("STRIP=${TOOLCHAIN_PREFIX}-strip")
CONFIG_OPTS+=("--disable-curve")
CONFIG_OPTS+=("--enable-static")
CONFIG_OPTS+=("--disable-shared")

cd ../..
./autogen.sh
mkdir -p "build-${HOST}"
cd "build-${HOST}"
../configure "${CONFIG_OPTS[@]}"
make -j"$(nproc)"
make install
cd ../builds/linux-arm64

# ── Verify architecture ────────────────────────────────────────
echo ""
echo "=== Architecture verification ==="
for lib in "${BUILD_PREFIX}"/lib/libzmq.*; do
    if [ -f "$lib" ]; then
        echo "$lib:"
        file "$lib"
        "${TOOLCHAIN_PREFIX}-readelf" -h "$lib" 2>/dev/null | grep -E "Class|Machine|OS/ABI" || true
        echo ""
    fi
done
echo "=== Contents of ${BUILD_PREFIX}/lib/ ==="
ls -la "${BUILD_PREFIX}/lib/"

echo ""
echo "Build successful. Artifacts at ${BUILD_PREFIX}"
