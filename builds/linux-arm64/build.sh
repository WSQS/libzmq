#!/usr/bin/env bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

export TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX:-aarch64-linux-gnu}"
export HOST="${HOST:-aarch64-linux-gnu}"
export BUILD_PREFIX="${BUILD_PREFIX:-${PWD}/prefix}"
export SODIUM_PREFIX="${PWD}/libsodium_prefix"

SODIUM_DIR="${PWD}/libsodium"

# ── Build libsodium (static) for the target ────────────────────
build_libsodium() {
    if [ -f "${SODIUM_PREFIX}/lib/libsodium.a" ]; then
        echo "libsodium already built, skipping..."
        return
    fi

    echo "=== Building libsodium for ${HOST} ==="
    rm -rf "${SODIUM_DIR}" "${SODIUM_PREFIX}"
    git clone --depth 1 -b stable https://github.com/jedisct1/libsodium.git "${SODIUM_DIR}"

    (
        cd "${SODIUM_DIR}"
        ./autogen.sh
        ./configure \
            --host="${HOST}" \
            --prefix="${SODIUM_PREFIX}" \
            --disable-shared \
            --enable-static \
            CC="${TOOLCHAIN_PREFIX}-gcc" \
            CXX="${TOOLCHAIN_PREFIX}-g++"
        make -j"$(nproc)"
        make install
    )
}

# ── Build libzmq ───────────────────────────────────────────────
build_libzmq() {
    echo "=== Building libzmq for ${HOST} ==="

    # Source config.sh from repo root
    # shellcheck source=../../config.sh
    source ../../config.sh
    set_config_opts

    CONFIG_OPTS=()
    CONFIG_OPTS+=("--host=${HOST}")
    CONFIG_OPTS+=("--prefix=${BUILD_PREFIX}")
    CONFIG_OPTS+=("CC=${TOOLCHAIN_PREFIX}-gcc")
    CONFIG_OPTS+=("CXX=${TOOLCHAIN_PREFIX}-g++")
    CONFIG_OPTS+=("AR=${TOOLCHAIN_PREFIX}-ar")
    CONFIG_OPTS+=("RANLIB=${TOOLCHAIN_PREFIX}-ranlib")
    CONFIG_OPTS+=("LD=${TOOLCHAIN_PREFIX}-ld")
    CONFIG_OPTS+=("STRIP=${TOOLCHAIN_PREFIX}-strip")
    CONFIG_OPTS+=("--with-libsodium=yes")
    CONFIG_OPTS+=("--disable-curve")
    CONFIG_OPTS+=("--enable-static")
    CONFIG_OPTS+=("--disable-shared")
    CONFIG_OPTS+=("CFLAGS=-I${SODIUM_PREFIX}/include")
    CONFIG_OPTS+=("CPPFLAGS=-I${SODIUM_PREFIX}/include -I${BUILD_PREFIX}/include")
    CONFIG_OPTS+=("CXXFLAGS=-I${SODIUM_PREFIX}/include")
    CONFIG_OPTS+=("LDFLAGS=-L${SODIUM_PREFIX}/lib -L${BUILD_PREFIX}/lib")

    cd ../..
    ./autogen.sh
    mkdir -p "build-${HOST}"
    cd "build-${HOST}"
    ../configure "${CONFIG_OPTS[@]}"
    make -j"$(nproc)"
    make install
    cd ../builds/linux-arm64
}

# ── Verify architecture ────────────────────────────────────────
verify_arch() {
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
}

# ── Main ───────────────────────────────────────────────────────
build_libsodium
build_libzmq
verify_arch

echo ""
echo "Build successful. Artifacts at ${BUILD_PREFIX}"
