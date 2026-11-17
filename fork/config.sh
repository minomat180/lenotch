# Fork settings, read by fork/debrand.sh, fork/sync-upstream.sh and the fork workflows.
APP_NAME="Notch"                       # shown in the menu bar, windows, Finder and the DMG
BUNDLE_ID="io.github.minomat180.notch" # separate from upstream, so both can be installed
FORK_REPO="minomat180/lenotch"
UPSTREAM_REPO="lephorx/lenotch"
UPSTREAM_BRANCH="main"
SIGN_IDENTITY_NAME="Notch Fork Signing" # CN of the cert in the FORK_SIGNING_P12 secret
