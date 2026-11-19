# Notch

A notch utility for MacBooks (macOS 14+): music, a file shelf, a timer and volume and
brightness indicators live in the black area around the camera. Notch is a fork of
[lephorx/lenotch](https://github.com/lephorx/lenotch) by lephorx, who wrote the app.
This fork exists to run the app without its branding while still getting upstream's
updates: it removes the Lenotch name, logo and icon and keeps itself in sync with upstream
through a script.

![The notch going from a playing-music pill to the open player, the file shelf, the volume indicator and a timer starting](docs/demo.gif)

*Captured from the running app on a MacBook, with generated demo audio and demo files.*

## What the fork adds

Apart from the name, glyph, icon and one crash fix, everything in the app is upstream's work.
The fork adds three things.

**A rebrand that survives upstream updates.** The fork never edits upstream code by hand.
`fork/debrand.sh` rewrites the tree after every merge: it renames the app, gives it its own
bundle ID so it installs next to the original, swaps the logo for an equalizer-bars glyph,
and points Sparkle updates at this fork's releases. Each edit is followed by a check that
its result is present. If upstream renames a string or moves a file so that an edit no
longer applies, the script exits with an error, and the sync fails instead of shipping a
build with the old branding.

**Releases that follow upstream.** A daily GitHub Action merges `lephorx/lenotch`, runs the
debrand script and pushes. When upstream tags a new version, the fork tags the same version
and builds a signed DMG and a Sparkle appcast. An installed copy finds the update through
Sparkle: automatically if update checks are on, otherwise through the menu bar icon's **Check for Updates…**

**A fix for a crash in upstream's code.** The fork's first release, built from upstream's
code against the macOS 26 SDK, crashed as soon as you pressed Get Started in the
first-launch window: AppKit threw "more Update Constraints in Window passes than there are
views in the window". The window was sized through Auto Layout from its SwiftUI content
(`sizingOptions = .preferredContentSize`), and upstream's code still does this. With the 26
SDK, every window resize invalidated the hosting view's safe area, which asked for another
constraints pass, which resized the window again. The fix measures the content and resizes
the window on the next run-loop turn, outside the constraints pass
([`WindowPresenter.swift`](fork/overlay/Sources/Lenotch/App/WindowPresenter.swift)). It
lives in `fork/overlay/`, so upstream merges can't undo it. The cost is that the overlay
copy also hides any later upstream change to that file, so it should go once upstream
fixes the crash.

## Install

Download `Notch.dmg` from the
[latest release](https://github.com/minomat180/lenotch/releases/latest) and drag Notch to
Applications. The app is signed with a self-signed certificate, not notarized, so macOS
blocks the first launch. Allow it under System Settings > Privacy & Security > Open Anyway,
or remove the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Notch.app
```

Later versions arrive through **Check for Updates…** in the menu bar icon.

## Build from source

Requires macOS 14+ and Xcode 26 (Xcode 27 builds, with the caveat under Limits). The DMG
target also needs `brew install create-dmg`.

```bash
SIGN_IDENTITY=- ./build.sh        # build/Notch.app, signed ad-hoc
SIGN_IDENTITY=- ./build.sh run    # build and launch it
```

Pass `SIGN_IDENTITY=-` for an ad-hoc signature, or `SIGN_IDENTITY="<certificate name>"` for
your own. Without it, `build.sh` exits after signing Sparkle unless the keychain has a
certificate named "Lenotch". CI passes the fork's self-signed certificate this way.

Custom AI usage providers are described in [docs/provider-config.md](docs/provider-config.md).

## How the fork is put together

| Path | Role |
| --- | --- |
| `fork/config.sh` | App name, bundle ID, fork and upstream repos |
| `fork/debrand.sh` | Removes the branding from the tree; safe to run repeatedly |
| `fork/overlay/` | Files copied over upstream's: glyph, icon, this README, the crash fix |
| `fork/sync-upstream.sh` | Merges upstream (upstream wins conflicts), runs `debrand.sh`, commits; `--push` also tags and starts a build |
| `.github/workflows/sync-upstream.yml` | Runs the sync daily |
| `.github/workflows/fork-build.yml` | Builds a universal DMG; on a version tag, publishes the release and appcast |

Conflicts resolve in upstream's favour and the fork's changes are re-applied by script, so
the result is upstream minus the branding, plus `fork/overlay/` and the fork's own
workflows and docs. The overlay is the weak spot: it replaces whole files, so an upstream
change to one of them is overwritten without warning.

## Limits

- Not notarized, so the first launch needs one of the two steps under Install.
- The Windows port that upstream also ships is removed here.
- The executable inside `Notch.app` is still named `Lenotch`. Only user-facing names change.
- GitHub's built-in Actions token can't push commits that change workflow files. When an
  upstream merge touches `.github/workflows/`, the daily sync fails until
  `fork/sync-upstream.sh --push` is run from a machine with push access, or a `SYNC_TOKEN`
  secret (a token with `repo` and `workflow` scopes) is added.
- With Xcode 27, `build.sh` produces a binary that records SDK 14.0 instead of 27.2 (the
  `--build-system native` SwiftPM option records the right value). macOS uses that value
  to decide whether an app gets the macOS 26 design, so these local builds don't. CI is
  pinned to Xcode 26 for this reason.
- This is a personal fork. Feature requests and app bugs belong
  [upstream](https://github.com/lephorx/lenotch/issues).

## Credits and license

The app (Now Playing, shelf, calendar, weather, timer, AI usage rings, HUDs and the rest)
is [lephorx/lenotch](https://github.com/lephorx/lenotch). Now Playing uses
[mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) (BSD-3-Clause,
`Vendor/MediaRemoteAdapter`).

Upstream has no license file, so lephorx keeps all rights to the app's code, and this fork
does not add a license on top of it. The files in `fork/` were written for this fork.
