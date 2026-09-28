#!/usr/bin/env bash

set -euo pipefail

BEAST_VERSION="2.7.7"
BEAST_ARCHIVE="BEAST.v${BEAST_VERSION}.Linux.x86.tgz"
BEAST_URL="https://github.com/CompEvol/beast2/releases/download/v${BEAST_VERSION}/${BEAST_ARCHIVE}"

INSTALL_ROOT="${BEAST_INSTALL_ROOT:-$HOME/.local/opt}"
DOWNLOAD_DIR="${TMPDIR:-/tmp}/beast2-download"

mkdir -p "$DOWNLOAD_DIR" "$INSTALL_ROOT"

ARCHIVE_PATH="$DOWNLOAD_DIR/$BEAST_ARCHIVE"

echo "Downloading BEAST2 ${BEAST_VERSION}..."
if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 -o "$ARCHIVE_PATH" "$BEAST_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$ARCHIVE_PATH" "$BEAST_URL"
else
    echo "Error: curl or wget is required."
    exit 1
fi

echo "Extracting $BEAST_ARCHIVE..."
tar -xzf "$ARCHIVE_PATH" -C "$INSTALL_ROOT"

BEAST_DIR="$(find "$INSTALL_ROOT" -maxdepth 1 -type d \
    -name "BEAST.v${BEAST_VERSION}*" -print -quit)"

if [[ -z "$BEAST_DIR" ]]; then
    echo "Error: could not find the extracted BEAST2 directory."
    exit 1
fi

chmod +x "$BEAST_DIR/bin/"* 2>/dev/null || true

ln -sfn "$BEAST_DIR" "$INSTALL_ROOT/beast2"

BEAST_HOME="$INSTALL_ROOT/beast2"
BEAST_BIN="$BEAST_HOME/bin"

if [[ ! -x "$BEAST_BIN/beast" ]]; then
    echo "Error: BEAST2 launcher was not found at:"
    echo "  $BEAST_BIN/beast"
    exit 1
fi

PROFILE="$HOME/.bashrc"

touch "$PROFILE"

grep -qxF 'export BEAST_HOME="$HOME/.local/opt/beast2"' "$PROFILE" \
    || echo 'export BEAST_HOME="$HOME/.local/opt/beast2"' >> "$PROFILE"

grep -qxF 'export PATH="$BEAST_HOME/bin:$PATH"' "$PROFILE" \
    || echo 'export PATH="$BEAST_HOME/bin:$PATH"' >> "$PROFILE"

export BEAST_HOME
export PATH="$BEAST_HOME/bin:$PATH"

echo
echo "BEAST2 installed successfully."
echo "Installation directory: $BEAST_HOME"
echo
"$BEAST_BIN/beast" -version
echo
echo "BEAGLE information:"
"$BEAST_BIN/beast" -beagle_info || true
echo
echo "Run 'source ~/.bashrc' before using beast in a new shell."
