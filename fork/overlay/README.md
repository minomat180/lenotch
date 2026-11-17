# Notch

A debranded fork of [lephorx/lenotch](https://github.com/lephorx/lenotch): the same
notch utility for MacBooks (Now Playing, shelf, calendar, weather, timer, AI usage,
battery, HUDs…) without the Lenotch logo, name or icon.

## Install

Download `Notch.dmg` from the [latest release](https://github.com/minomat180/lenotch/releases/latest)
and drag Notch to Applications. It's self-signed, not notarized, so on first launch
right-click → Open, or run:

```bash
xattr -dr com.apple.quarantine /Applications/Notch.app
```

Updates come through **Check for Updates…** in the menu bar icon (Sparkle), from this
fork's releases.

## How the fork stays current

| | |
|---|---|
| `fork/config.sh` | app name, bundle ID, repos |
| `fork/debrand.sh` | strips the branding from the tree (idempotent) |
| `fork/overlay/` | files copied over upstream's: neutral glyph, icon, this README |
| `fork/sync-upstream.sh` | merges upstream (its side wins conflicts), re-runs `debrand.sh`, commits |
| `.github/workflows/sync-upstream.yml` | runs the sync daily; mirrors upstream version tags as releases |
| `.github/workflows/fork-build.yml` | builds the DMG; on a version tag publishes a release + appcast |

`debrand.sh` fails if one of its edits stops applying, so a sync that would let
branding back in fails instead (you get the usual Actions failure email).

Sync by hand any time:

```bash
fork/sync-upstream.sh          # merge + debrand + commit
fork/sync-upstream.sh --push   # also push, tag new upstream versions and start the build
```

GitHub's built-in token can't push commits that touch workflow files, which some
upstream merges do. Add a `SYNC_TOKEN` secret (a PAT with `repo` and `workflow`
scopes) to let the daily sync handle those, or run the sync locally when it fails.

Secrets used: `SPARKLE_PRIVATE_KEY` (update signing, public half in
`fork/sparkle-public-key.txt`), `FORK_SIGNING_P12` / `FORK_SIGNING_PASSWORD`
(self-signed code-signing cert, so macOS keeps permissions across updates).

The Windows port is removed in this fork.

## Build locally

macOS 14+, Xcode / Swift 6, `brew install create-dmg` for the DMG:

```bash
./build.sh run       # build build/Notch.app and launch it
./build.sh install   # copy to /Applications and launch
./build.sh dmg       # build/Notch.dmg
```

Custom AI usage providers: see [docs/provider-config.md](docs/provider-config.md).
Now Playing uses [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter)
(BSD-3, `Vendor/MediaRemoteAdapter`).
