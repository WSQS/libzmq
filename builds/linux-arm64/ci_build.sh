#!/usr/bin/env bash
set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"

export BUILD_PREFIX="${BUILD_PREFIX:-${PWD}/prefix}"

# Clean up any previous build artifacts
rm -rf "${BUILD_PREFIX}"
mkdir -p "${BUILD_PREFIX}"

./build.sh
