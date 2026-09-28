#!/usr/bin/env bash
# Install FigTree and Tracer (Linux tarballs from GitHub releases) in a Renku session.
# Usage: bash install_figtree_tracer.sh
set -euo pipefail

FIGTREE_VERSION="1.4.4"
TRACER_VERSION="1.7.2"

# Install into the persistent Renku mount if available, otherwise $HOME
PREFIX="${RENKU_MOUNT_DIR:-$HOME}/tools"
BIN_DIR="$PREFIX/bin"
mkdir -p "$PREFIX" "$BIN_DIR"

# --- Pick a Java runtime: reuse the JRE bundled with BEAST2, else system java ---
JAVA=""
if command -v beast >/dev/null 2>&1; then
  BEAST_HOME="$(dirname "$(readlink -f "$(command -v beast)")")/.."
  [ -x "$BEAST_HOME/jre/bin/java" ] && JAVA="$(readlink -f "$BEAST_HOME/jre/bin/java")"
fi
[ -z "$JAVA" ] && command -v java >/dev/null 2>&1 && JAVA="$(command -v java)"
if [ -z "$JAVA" ]; then
  echo "ERROR: no Java runtime found (neither BEAST2's bundled JRE nor 'java' on PATH)." >&2
  exit 1
fi
echo "Using Java: $JAVA"
"$JAVA" -version 2>&1 | head -1

cd "$PREFIX"

# --- FigTree ---
echo "Downloading FigTree v$FIGTREE_VERSION..."
curl -fL -o "FigTree_v${FIGTREE_VERSION}.tgz" \
  "https://github.com/rambaut/figtree/releases/download/v${FIGTREE_VERSION}/FigTree_v${FIGTREE_VERSION}.tgz"
tar -xzf "FigTree_v${FIGTREE_VERSION}.tgz"
rm "FigTree_v${FIGTREE_VERSION}.tgz"
FIGTREE_JAR="$(find "$PREFIX/FigTree_v${FIGTREE_VERSION}" -name 'figtree.jar' | head -1)"

# --- Tracer ---
echo "Downloading Tracer v$TRACER_VERSION..."
curl -fL -o "Tracer_v${TRACER_VERSION}.tgz" \
  "https://github.com/beast-dev/tracer/releases/download/v${TRACER_VERSION}/Tracer_v${TRACER_VERSION}.tgz"
tar -xzf "Tracer_v${TRACER_VERSION}.tgz"
rm "Tracer_v${TRACER_VERSION}.tgz"
TRACER_JAR="$(find "$PREFIX" -maxdepth 3 -path "*Tracer*" -name 'tracer.jar' | head -1)"

# --- Launcher scripts that use the Java found above ---
cat > "$BIN_DIR/figtree" <<EOF
#!/usr/bin/env bash
exec "$JAVA" -Xms64m -Xmx1024m -jar "$FIGTREE_JAR" "\$@"
EOF

cat > "$BIN_DIR/tracer" <<EOF
#!/usr/bin/env bash
exec "$JAVA" -Xms64m -Xmx2048m -jar "$TRACER_JAR" "\$@"
EOF

chmod +x "$BIN_DIR/figtree" "$BIN_DIR/tracer"

# --- Add to PATH for future shells ---
LINE="export PATH=\"$BIN_DIR:\$PATH\""
grep -qxF "$LINE" "$HOME/.bashrc" 2>/dev/null || echo "$LINE" >> "$HOME/.bashrc"

echo
echo "Done."
echo "  FigTree jar: $FIGTREE_JAR"
echo "  Tracer jar:  $TRACER_JAR"
echo "Run:  export PATH=\"$BIN_DIR:\$PATH\"   (or open a new terminal)"
echo "Then: figtree   /   tracer   (both need a graphical display)"
