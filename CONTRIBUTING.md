# Contributing

This fork only carries the rebranding, the upstream sync and fixes that upstream has not
picked up yet. Changes to the app belong in [lephorx/lenotch](https://github.com/lephorx/lenotch);
the fork receives them through the daily sync.

Pull requests here make sense for `fork/` and `.github/workflows/`. Files that also exist
upstream are taken from upstream on every merge (conflicts resolve in its favour), so a
lasting change to one of them goes through `fork/debrand.sh` or `fork/overlay/`.
