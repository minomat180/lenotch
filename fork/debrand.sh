#!/usr/bin/env bash
# Strips the upstream branding from the working tree. Idempotent: run it after every
# upstream merge (fork/sync-upstream.sh does). Fails loudly when an edit no longer
# applies, so a changed upstream file gets noticed instead of slipping through.
set -euo pipefail
cd "$(dirname "$0")/.."
source fork/config.sh
SPARKLE_PUBLIC_KEY="$(cat fork/sparkle-public-key.txt)"
export APP_NAME BUNDLE_ID FORK_REPO SPARKLE_PUBLIC_KEY

fail() { echo "debrand: $*" >&2; exit 1; }

# Runs a perl substitution over a file and fails if the file doesn't match `check`
# afterwards (so a pattern that stopped matching upstream is caught).
edit() {
  local file="$1" expr="$2" check="$3"
  [ -f "$file" ] || fail "$file is missing"
  perl -0pi -e "$expr" "$file"
  grep -qF -- "$check" "$file" || fail "$file: expected '$check' after editing"
}

# 1. Fork-owned replacements: neutral glyph (LogoShape.swift), app icon, README.
cp -R fork/overlay/. .

# 2. Branded files the fork doesn't need.
rm -rf windows docs/lenotchpreview.png logo.png \
  Resources/logo.png Resources/lephor_logo_white.png \
  scripts/make_icon.sh scripts/make_icon.swift scripts/crop_logo.swift scripts/make_white_logo.swift \
  .github/workflows/build-dmg.yml

# 3. Info.plist: name, bundle ID, permission prompts and the Sparkle update feed.
PLIST=Resources/Info.plist
edit $PLIST 's{(<key>CFBundleDisplayName</key>\s*<string>)[^<]*}{$1$ENV{APP_NAME}}' "<string>$APP_NAME</string>"
edit $PLIST 's{(<key>CFBundleName</key>\s*<string>)[^<]*}{$1$ENV{APP_NAME}}' "<string>$APP_NAME</string>"
edit $PLIST 's{(<key>CFBundleIdentifier</key>\s*<string>)[^<]*}{$1$ENV{BUNDLE_ID}}' "<string>$BUNDLE_ID</string>"
edit $PLIST 's{(<key>SUFeedURL</key>\s*<string>)[^<]*}{$1https://github.com/$ENV{FORK_REPO}/releases/latest/download/appcast.xml}' "github.com/$FORK_REPO/releases"
edit $PLIST 's{(<key>SUPublicEDKey</key>\s*<string>)[^<]*}{$1$ENV{SPARKLE_PUBLIC_KEY}}' "$SPARKLE_PUBLIC_KEY"
# Permission prompts start with the app's name. (CFBundleExecutable stays Lenotch: the binary's name.)
perl -pi -e 's{<string>Lenotch }{<string>$ENV{APP_NAME} }g' $PLIST
grep -Pzq '<key>CFBundleExecutable</key>\s*<string>Lenotch</string>' $PLIST || fail "$PLIST: CFBundleExecutable isn't Lenotch"
! grep -v '<string>Lenotch</string>' $PLIST | grep -q 'Lenotch\|lephor' || fail "$PLIST still mentions upstream"

# 4. User-visible Swift strings. Only string literals are touched, and not internal
#    ones (logs, queue labels, keychain services, folders, plist keys, headers).
find Sources -name '*.swift' -print0 | xargs -0 perl -pi -e '
  next if /NSLog|DispatchQueue|appendingPathComponent|forHTTPHeaderField|keychainService|LenotchRelease|persistentDomain/;
  s{("(?:[^"\\]|\\.)*")}{ my $s = $1; $s =~ s/(?<![.\w])Lenotch(?!\w)/$ENV{APP_NAME}/g; $s }ge;
  s{lephorx/lenotch}{$ENV{FORK_REPO}}g;
'
if grep -rnE '(Text|Button|title:|Label)\("[^"]*Lenotch' Sources; then fail "user-visible 'Lenotch' strings left (above)"; fi
! grep -rn 'lephorx/lenotch' Sources || fail "upstream URLs left in Sources (above)"

# 5. Build and packaging: app bundle, DMG and release-notes names.
edit build.sh 's{Lenotch\.app}{$ENV{APP_NAME}.app}g; s{Lenotch\.dmg}{$ENV{APP_NAME}.dmg}g; s{"Lenotch Installer"}{"$ENV{APP_NAME} Installer"}g' "build/$APP_NAME.app"
edit scripts/style_dmg.applescript 's{/Lenotch\.app/}{/$ENV{APP_NAME}.app/}g' "/$APP_NAME.app/"
edit scripts/release_notes.py 's{Lenotch\.html}{$ENV{APP_NAME}.html}g; s{in Lenotch }{in $ENV{APP_NAME} }g' "$APP_NAME.html"

echo "debrand: done ($APP_NAME, $BUNDLE_ID)"
