# Snipz — agent rules

## Version bump (MANDATORY after every task)

After completing any task that changes app code or content (`lib/`, `assets/`,
`android/`, `pubspec.yaml` dependencies, `tools/`), bump `version:` in
`pubspec.yaml` **before** handing over the commit message:

- **Always** increment the build number (the `+N` part) by 1.
  Android refuses to install an APK over an existing one with a lower
  `versionCode`, so this must never go backwards.
- Bump the **patch** (`x.y.Z`) for fixes, tweaks, or new component ports.
- Bump the **minor** (`x.Y.0`) for new app features (new screen, new
  capability in the viewer).
- Docs-only changes (`docs/`, `*.md` at root) do **not** require a bump.

Example: `1.0.0+1` → after a task adding a component → `1.0.1+2`.

The CI workflow (`.github/workflows/build-apk.yml`) reads this version to name
the APK (`snipz_vX.Y.Z_<timestamp>.apk`) and publishes it to the `latest`
GitHub Release on every push to `main`. Updating the app = download the new
APK and install over the old one (same signing key, data preserved).

## Session flag (MANDATORY when adding or fixing components)

`SESSION.yaml` at the repo root marks the current work batch ("đợt") — the
app renders NEW/FIX badges and the "✦ New" gallery filter from it. Exactly
ONE latest session exists; there is no history.

After any task that adds components or fixes existing ones, update it
**before** handing over the commit message:

- Continuing the same batch of work (same stream of related tasks, e.g. a
  port followed by its bug fixes): keep `id`/`title`/`date`, append the new
  ids to `added:` / `fixed:`.
- Starting an unrelated batch: replace the whole file — new `id`
  (`YYYY-MM-DD-slug`), `title`, `date`, fresh `added`/`fixed` lists.
- A component id must appear in only ONE of the two lists (added wins for a
  brand-new component that also got tweaked). `validate.dart` (#11) enforces
  existence and disjointness; `build_index.dart` embeds the block into
  `assets/index.json` — run it after editing, or validate fails stale (#8).

## Git

The user pushes commits themselves — provide an English commit message, do not
push.
