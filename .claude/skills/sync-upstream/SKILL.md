---
name: sync-upstream
description: Rebase this fork's commits onto the latest we-promise/sure upstream release, resolving known conflict points, without touching main until the user has verified it. Use when asked to update/sync the fork with upstream Sure.
---

# Sync fork with upstream

Args: optional target tag/ref (e.g. `v0.7.3` or `upstream/main`). Default: latest stable tag.

1. `git fetch upstream --tags`. If no target given, pick the latest release via
   `gh release list --repo we-promise/sure --limit 5` (prefer a stable tag over
   an `-alpha`/`upstream/main` tip unless asked otherwise).
2. Safety net: `git branch backup/pre-<target>-sync main`.
3. `git checkout -b upstream-sync/<target> main`
4. `git rebase <target>`, resolving conflicts commit-by-commit
   (`git status` → edit → `git add` → `git rebase --continue`). Known
   recurring conflict spots in this fork:
   - `app/models/family.rb` — two `include ...` lines; keep both fork's and
     upstream's modules in each.
   - `config/routes.rb`, `app/helpers/settings_helper.rb`,
     `app/views/settings/_settings_nav.html.erb`,
     `config/locales/views/settings/en.yml` — transfer-match-groups entries;
     keep both sides' additions.
   - `app/controllers/pages_controller.rb` — dashboard sections array. If
     upstream's `build_dashboard_sections` sections gained a
     `layout: section_layout(...)` key, add it to the fork's own widget
     hashes too (Investments Full, Currency Breakdown) — a clean textual
     merge here can silently miss it.
   - `app/models/concerns/enrichable.rb` / `app/models/family/syncer.rb` —
     fork's lock-bypass commits net to zero (added, then reverted); resolve
     to upstream's content both times.
   - Deleted GH workflow files (mobile/chart/preview/publish CI) — keep them
     deleted; fork only uses `.github/workflows/build.yml`.
5. Sanity pass: `grep -rn '^<<<<<<<' .` (no leftovers), `git log --oneline
   <target>..HEAD` matches the original fork-commit list, `ls db/migrate`
   has both the new upstream migrations and the fork's own. Don't hand-edit
   `db/schema.rb` — `bin/docker-entrypoint` runs `db:prepare` on container
   boot, so a stale schema.rb isn't a deploy blocker.
6. `git push -u origin upstream-sync/<target>` (plain branch, doesn't
   trigger the build). Let the user review/test before going further.
7. Once approved: `git checkout main && git reset --hard
   upstream-sync/<target> && git push --force-with-lease origin main` —
   triggers the GHCR build → dispatch to `sure-deploy` → VM deploy.
8. Verify: `gh run watch <run-id> --repo shebetov/sure`, then the
   corresponding run in `shebetov/sure-deploy`, then SSH the VM and check
   `docker compose logs web worker` for migration/boot errors.
9. Rollback if needed: `git reset --hard backup/pre-<target>-sync && git
   push --force-with-lease origin main`, then let the redeploy cycle run.
