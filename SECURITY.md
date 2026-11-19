# Security

Notch is a personal fork of [lephorx/lenotch](https://github.com/lephorx/lenotch), maintained
by one person with no response-time promise.

- A problem in the app itself (anything outside `fork/`) is upstream code. Report it to
  lephorx/lenotch, privately if it is exploitable.
- For a problem in the fork's own parts (`fork/`, `.github/workflows/`, the release signing
  or the Sparkle update feed), use
  [private vulnerability reporting](https://github.com/minomat180/lenotch/security/advisories/new)
  on this repository.

Releases are signed with a self-signed certificate and their updates with a Sparkle EdDSA
key; the public half is in `fork/sparkle-public-key.txt`.
