# Notch

A notch utility for MacBooks (macOS 14+): music, a file shelf, a timer and volume and
brightness indicators live in the black area around the camera. Notch is a fork of
[lephorx/lenotch](https://github.com/lephorx/lenotch) by lephorx, who wrote the app.
This fork removes the Lenotch name, logo and icon and keeps itself in sync with upstream
through a script.

![The notch going from a playing-music pill to the open player, the file shelf, the volume indicator and a running timer](docs/demo.gif)

*Captured from the running app on a MacBook, with generated demo audio and demo files.*

## What the fork adds

Apart from the name, glyph and icon, everything in the app is upstream's work. The fork adds
three things around it.

**A rebrand that survives upstream updates.** The fork never edits upstream code by hand.
`fork/debrand.sh` rewrites the tree after every merge: it renames the app, gives it its own
bundle ID so it installs next to the original, swaps the logo for an equalizer-bars glyph,
and points Sparkle updates at this fork's releases. Each edit checks its own result. If
upstream renames a string or moves a file so that an edit no longer applies, the script
exits with an error, and the sync fails instead of shipping a build with the old branding.

**Releases that follow upstream.** A daily GitHub Action merges `lephorx/lenotch`, runs the
debrand script and pushes. When upstream tags a new version, the fork tags the same version
and builds a signed DMG and a Sparkle appcast, so an installed copy offers the update on its
own.

**A fix for a crash upstream still has.** Built against the macOS 26 SDK, the app crashed
as soon as you pressed Get Started in the first-launch window: AppKit threw
"more Update Constraints in Window passes than there are views in the window". The window
was sized through Auto Layout from its SwiftUI content. Under the 26 SDK each resize reset
the content's safe area, which requested another layout pass, which resized the window
again. The fix measures the content with `sizeThatFits` and resizes the window on the next
run-loop turn, outside the layout pass
([`WindowPresenter.swift`](fork/overlay/Sources/Lenotch/App/WindowPresenter.swift)). It lives
in `fork/overlay/`, so upstream merges can't undo it, and it can be dropped once upstream
fixes the bug.

## Install

Download `Notch.dmg` from the
[latest release](https://github.com/minomat180/lenotch/releases/latest) and drag Notch to
Applications. The app is signed with a self-signed certificate, not notarized, so macOS
blocks the first launch. Remove the quarantine flag once:

```bash
xattr -dr com.apple.quarantine /Applications/Notch.app
```

Later versions arrive through **Check for Updates…** in the menu bar icon.

## Build from source

Requires macOS 14+ and Xcode or a Swift 6 toolchain. The DMG target also needs
`brew install create-dmg`.

```bash
SIGN_IDENTITY=- ./build.sh        # build/Notch.app, signed ad-hoc
SIGN_IDENTITY=- ./build.sh run    # build and launch it
```

Without `SIGN_IDENTITY=-`, `build.sh` looks for a code-signing certificate and stops if it
finds none. CI imports the fork's self-signed certificate for releases.

## How the fork is put together

| Path | Role |
| --- | --- |
| `fork/config.sh` | App name, bundle ID, fork and upstream repos |
| `fork/debrand.sh` | Removes the branding from the tree; safe to run repeatedly |
| `fork/overlay/` | Files copied over upstream's: glyph, icon, this README, the crash fix |
| `fork/sync-upstream.sh` | Merges upstream (upstream wins conflicts), runs `debrand.sh`, commits; `--push` also tags and starts a build |
| `.github/workflows/sync-upstream.yml` | Runs the sync daily |
| `.github/workflows/fork-build.yml` | Builds a universal DMG; on a version tag, publishes the release and appcast |

Because conflicts resolve in upstream's favour and the fork's changes are re-applied by
script, the fork is always "upstream minus the branding, plus `fork/overlay/`". It never
drifts into a hand-maintained copy.

## Limits

- Not notarized, so the first launch needs the `xattr` step above.
- The Windows port that upstream also ships is removed here.
- The executable inside `Notch.app` is still named `Lenotch`. Only user-facing names change.
- GitHub's built-in Actions token can't push commits that change workflow files. When an
  upstream merge touches `.github/workflows/`, the daily sync fails until it is run by hand
  or a `SYNC_TOKEN` secret (a token with `repo` and `workflow` scopes) is added.
- With Xcode 27, `build.sh` produces a binary that records SDK 14.0 instead of 27.
  macOS reads that value to decide whether an app gets the macOS 26 design, so these local
  builds don't. Releases are built on CI with Xcode 26.6 (SDK 26.5) and are not affected.
- This is a personal fork. Feature requests and app bugs belong
  [upstream](https://github.com/lephorx/lenotch/issues).

## Credits and license

The app (Now Playing, shelf, calendar, weather, timer, AI usage rings, HUDs and the rest)
is [lephorx/lenotch](https://github.com/lephorx/lenotch). Now Playing uses
[mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) (BSD-3-Clause,
`Vendor/MediaRemoteAdapter`). Custom AI usage providers are described in
[docs/provider-config.md](docs/provider-config.md).

Upstream publishes no license file, so this fork adds none. The code is lephorx's and keeps
upstream's terms; the files in `fork/` were written for this fork.
