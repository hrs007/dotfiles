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

if ! grep -q '^maximized[[:space:]]*=' "$CONFIG"; then
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

# Clean any stale Neovide IPC socket
rm -f "$APP_SUPPORT_DIR/neovide-stable.sock"

# Build native macOS OpenWithNeovide launcher app
# This bypasses Neovide's macOS cold-start AppleEvent drop/crash bug when opening files from Finder.
NEOVIDE_BIN=$(command -v neovide || echo "/opt/homebrew/bin/neovide")
LAUNCHER_APP="/Applications/OpenWithNeovide.app"
cat << EOF | osacompile -o "$LAUNCHER_APP"
on open theFiles
	repeat with aFile in theFiles
		set filePath to POSIX path of aFile
		do shell script "$NEOVIDE_BIN " & quoted form of filePath & " >/dev/null 2>&1 &"
	end repeat
end open

on run
	do shell script "$NEOVIDE_BIN >/dev/null 2>&1 &"
end run
EOF

if [ -f "/Applications/Neovide.app/Contents/Resources/Neovide.icns" ]; then
  cp "/Applications/Neovide.app/Contents/Resources/Neovide.icns" "$LAUNCHER_APP/Contents/Resources/applet.icns"
fi
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.hrs007.OpenWithNeovide" "$LAUNCHER_APP/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.hrs007.OpenWithNeovide" "$LAUNCHER_APP/Contents/Info.plist" 2>/dev/null || true
codesign --force --deep --sign - "$LAUNCHER_APP" >/dev/null 2>&1 || true

if command -v duti >/dev/null 2>&1; then
  # Route common source types to OpenWithNeovide when opened from Finder.
  for extension in \
    py pyw \
    js jsx \
    c h cc cpp cxx hh hpp hxx \
    lua txt md json toml yaml yml; do
    duti -s com.hrs007.OpenWithNeovide "$extension" all 2>/dev/null || true
  done
fi

echo "Configured Neovide to run $NVIM_BIN."
echo "Created OpenWithNeovide.app in /Applications for reliable Finder double-click file opening."
if ! command -v duti >/dev/null 2>&1; then
  echo "To make it your default in Finder: select any file, press Command-I, choose 'OpenWithNeovide' under Open with, and click Change All."
else
  echo "Common file extensions registered to OpenWithNeovide via duti."
fi

