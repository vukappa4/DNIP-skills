#!/bin/sh
# Installs Espanso and keeps the research skills in sync with GitHub.
# Run in Terminal:
#   /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/vukappa4/research-skills/main/install-mac.sh)"
# Safe to run again: it updates everything in place.
set -e

ESPANSO_DMG="https://github.com/espanso/espanso/releases/download/v2.4.1/Espanso-Mac-Universal.dmg"
CONFIG="$HOME/Library/Application Support/espanso"
SYNC_DIR="$HOME/Library/Application Support/espanso-sync"
PLIST="$HOME/Library/LaunchAgents/local.research-skills-sync.plist"

echo "1/4 Installing Espanso..."
TMP=$(mktemp -d)
curl -fsSL -o "$TMP/espanso.dmg" "$ESPANSO_DMG"
yes | hdiutil attach -nobrowse -quiet -mountpoint "$TMP/mnt" "$TMP/espanso.dmg" >/dev/null
APP=$(ls -d "$TMP"/mnt/*.app | head -1)
APP_NAME=$(basename "$APP")
rm -rf "/Applications/$APP_NAME"
cp -R "$APP" /Applications/
hdiutil detach -quiet "$TMP/mnt"
rm -rf "$TMP"

mkdir -p "$CONFIG/config" "$CONFIG/match" "$SYNC_DIR" "$HOME/Library/LaunchAgents"
[ -f "$CONFIG/config/default.yml" ] || echo "# Espanso global settings. Defaults apply." > "$CONFIG/config/default.yml"

echo "2/4 Installing the skill updater..."
cat > "$SYNC_DIR/sync.sh" <<'EOF'
#!/bin/sh
# Mirrors every *.yml at the root of the research-skills repo into Espanso's match folder.
# Espanso reloads by itself when the folder changes.
set -e
ZIP="https://github.com/vukappa4/research-skills/archive/refs/heads/main.zip"
DEST="$HOME/Library/Application Support/espanso/match/research-skills"
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
curl -fsSL --max-time 60 "$ZIP" -o "$W/repo.zip"
unzip -q "$W/repo.zip" -d "$W/x"
mkdir "$W/new"
for f in "$W"/x/*/*.yml; do
  if [ -f "$f" ] && grep -q '^matches:' "$f"; then cp "$f" "$W/new/"; fi
done
if ! ls "$W/new"/*.yml >/dev/null 2>&1; then
  echo "research-skills: no skill files in the download" >&2
  exit 1
fi
if diff -rq "$W/new" "$DEST" >/dev/null 2>&1; then exit 0; fi
mkdir -p "$(dirname "$DEST")"
if [ -d "$DEST" ]; then mv "$DEST" "$W/old"; fi
mv "$W/new" "$DEST"
echo "research-skills updated"
EOF

echo "3/4 Downloading the skills..."
/bin/sh "$SYNC_DIR/sync.sh"
ls "$CONFIG/match/research-skills"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>Label</key><string>local.research-skills-sync</string>
<key>ProgramArguments</key><array><string>/bin/sh</string><string>$SYNC_DIR/sync.sh</string></array>
<key>StartInterval</key><integer>600</integer>
<key>RunAtLoad</key><true/>
</dict></plist>
EOF
launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "4/4 Starting Espanso..."
open "/Applications/$APP_NAME"
echo
echo "Done. If Espanso asks for Accessibility access, allow it in"
echo "System Settings > Privacy & Security > Accessibility, then quit and reopen Espanso."
echo "Test: type :analysis in Notes."
