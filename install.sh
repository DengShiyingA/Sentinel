#!/bin/bash
set -e

REPO="https://github.com/DengShiyingA/Sentinel.git"
INSTALL_DIR="$HOME/.sentinel/cli"

echo ""
echo "  🛡️  Sentinel Installer"
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "  ✗ Node.js not found. Install from https://nodejs.org (v20+)"
  exit 1
fi

NODE_VER=$(node -e "console.log(process.versions.node.split('.')[0])")
if [ "$NODE_VER" -lt 18 ]; then
  echo "  ✗ Node.js v18+ required (found v$NODE_VER)"
  exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "  ↻ Updating existing install..."
  git -C "$INSTALL_DIR" pull --quiet
else
  echo "  ↓ Downloading Sentinel..."
  rm -rf "$INSTALL_DIR"
  git clone --quiet --depth 1 "$REPO" "$INSTALL_DIR"
fi

# Build CLI
echo "  ⚙  Building CLI..."
cd "$INSTALL_DIR/packages/sentinel-cli"
npm install --silent
npm run build --silent

# Link globally
npm link --silent 2>/dev/null || sudo npm link --silent

# Inject Claude Code hook
echo "  🔗 Installing Claude Code hook..."
sentinel install

echo ""
echo "  ✅ Done! Sentinel installed."
echo ""
echo "  Usage:"
echo "    sentinel run      # start with Claude Code (recommended)"
echo "    sentinel start    # start hook server only"
echo ""
echo "  Open Sentinel on your iPhone → scan the QR code to connect."
echo ""
