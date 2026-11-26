# The release workflow depends on exact text in `export_presets.cfg`

- **Type:** robustness (CI)
- **Priority:** medium
- **Area:** CI

## Description
On tag builds, `build.yml` appends `debug/*` to each preset's `exclude_filter` with `sed`, and expects the exact line `exclude_filter="tools/*"` to match 4 times. The `release` job also expects exactly 4 artifacts. If the editor rewrites that line (a new exclude, reordered filters) or a platform is added, the release fails. The count check catches the mismatch, but only at release time.

## Ideas
- Match `exclude_filter="..."` generically and append `,debug/*` whatever the current value is.
- Run that rewrite plus a dry-run check in the normal PR build as well, so breakage shows up before a tag.
- Derive the expected artifact count from the matrix.
