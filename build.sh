#!/usr/bin/env bash
# Build machin-demo-cyberpunk. Uses a system raylib if installed; otherwise
# vendors raylib's prebuilt static release into vendor/ (no root). The committed
# source stays system-style; the vendored path is injected into a throwaway copy.
# Requires machin v0.49.0+ (noise2/noise3) and the pointer/array FFI (v0.47-0.48).
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
SRC=cyberpunk.src

have_system_raylib() {
    pkg-config --exists raylib 2>/dev/null && return 0
    [ -f /usr/include/raylib.h ] || [ -f /usr/local/include/raylib.h ]
}

if have_system_raylib; then
    "$MACHIN" encode "$SRC" > cyberpunk.mfl
else
    RL_VER=5.0
    RL_TAR="raylib-${RL_VER}_linux_amd64"
    RL_DIR="vendor/${RL_TAR}"
    if [ ! -f "${RL_DIR}/lib/libraylib.a" ]; then
        echo "raylib not found system-wide; vendoring the prebuilt static release..."
        mkdir -p vendor
        curl -fsSL "https://github.com/raysan5/raylib/releases/download/${RL_VER}/${RL_TAR}.tar.gz" \
            | tar xz -C vendor
    fi
    INC="$PWD/${RL_DIR}/include"; LIB="$PWD/${RL_DIR}/lib"
    tmp="$(mktemp)"
    "$MACHIN" encode "$SRC" \
        | sed "s#header \"raylib.h\"#cflags \"-I${INC} -L${LIB}\" header \"raylib.h\"#; s#link \"raylib\"#link \":libraylib.a\"#" \
        > "$tmp"
    mv "$tmp" cyberpunk.mfl
fi

"$MACHIN" build cyberpunk.mfl -o machin-demo-cyberpunk
echo "built ./machin-demo-cyberpunk"
