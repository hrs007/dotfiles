#!/bin/sh
set -eu

NVIM_BIN=$(command -v nvim || true)
if [ -z "$NVIM_BIN" ]; then
  echo "Neovim was not found on PATH. Install Neovim first, then run this script." >&2
  exit 1
fi

CONFIG_ROOT=${XDG_CONFIG_HOME:-"$HOME/.config"}
CONFIG_DIR="$CONFIG_ROOT/neovide"
CONFIG="$CONFIG_DIR/config.toml"
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG" ] && grep -q '^neovim-bin[[:space:]]*=' "$CONFIG"; then
  sed -i '' "s|^neovim-bin[[:space:]]*=.*|neovim-bin = \"$NVIM_BIN\"|" "$CONFIG"
else
  printf '\nneovim-bin = "%s"\n' "$NVIM_BIN" >> "$CONFIG"
fi

if ! grep -q '^maximized[[:space:]]*=' "$CONFIG" \
  && ! grep -q '^grid[[:space:]]*=' "$CONFIG" \
  && ! grep -q '^size[[:space:]]*=' "$CONFIG"; then
  sed -i '' '1i\
maximized = true\
' "$CONFIG"
fi

# Keep Finder-opened files in the current editor instead of opening another
# Neovide tab alongside the startup dashboard.
if grep -q '^tabs[[:space:]]*=' "$CONFIG"; then
  sed -i '' 's/^tabs[[:space:]]*=.*/tabs = false/' "$CONFIG"
else
  sed -i '' '1i\
tabs = false\
' "$CONFIG"
fi

# Prefer the Nerd Font already installed with this setup for a closer match to
# the terminal, while preserving any existing font choice.
if ! grep -q '^\[font\]' "$CONFIG"; then
  cat >> "$CONFIG" <<'TOML'

[font]
normal = ["JetBrainsMono Nerd Font Mono"]
size = 18.0
TOML
else
  sed -i '' '/^\[font\]/,/^\[/ s/^size[[:space:]]*=.*/size = 18.0/' "$CONFIG"
fi

# Also sync to ~/Library/Application Support/neovide/config.toml
APP_SUPPORT_DIR="$HOME/Library/Application Support/neovide"
mkdir -p "$APP_SUPPORT_DIR"
cp "$CONFIG" "$APP_SUPPORT_DIR/config.toml"

# Clean any stale Neovide IPC socket or obsolete launcher app
rm -f "$APP_SUPPORT_DIR/neovide-stable.sock"
rm -rf /Applications/OpenWithNeovide.app

if command -v duti >/dev/null 2>&1; then
  # Route common source types to Neovide when opened from Finder.
  for extension in \
    py pyw \
    js jsx \
    c h cc cpp cxx hh hpp hxx; do
    duti -s com.neovide.neovide "$extension" editor 2>/dev/null || true
  done
fi

echo "Configured Neovide to run $NVIM_BIN."
echo "Neovide will use the same Neovim configuration and configured window geometry."
if ! command -v duti >/dev/null 2>&1; then
  echo "To make Neovide the Finder default, select a source file, press Command-I, choose Neovide under Open with, and click Change All."
else
  echo "For .ts or .tsx files, set the Finder default manually with Command-I > Open with > Neovide > Change All if another app currently claims the extension."
fi

