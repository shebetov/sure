---
name: sync-upstream
description: Rebase this fork's commits onto the latest we-promise/sure upstream release, resolving known conflict points, without touching main until the user has verified it. Use when asked to update/sync the fork with upstream Sure.
---

# Sync fork with upstream

Args: optional target tag/ref (e.g. `v0.7.3` or `upstream/main`). Default: latest stable tag.

1. `git fetch upstream --tags`. If no target given, pick the latest release via
   `gh release list --repo we-promise/sure --limit 5` (prefer a stable tag over
   an `-alpha`/`upstream/main` tip unless asked otherwise).
   - **Ancestry check (v0.7.4 lesson):** upstream tags releases on release
     branches that are *not ancestors of `main`* (`git merge-base --is-ancestor
     <tag> <target>`). When the tag lineage diverged, a plain rebase replays ~20
     stale release-line commits alongside the fork's. In that case cherry-pick
     the fork commits onto the target instead:
     `git checkout -b upstream-sync/<target> <target-sha>` then
     `git cherry-pick $(git rev-list --reverse <previous-tag>..main)`.
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
5. Re-diff `sure-deploy/config/api_overrides.rb` against the upstream methods
   it copies (`Api::V1::TradesController#trade_params`, security-prices and
   exchange-rates controllers). It redefines whole methods via `class_eval`,
   so upstream edits to them are silently discarded — git reports nothing,
   the app boots fine. An omitted `:type` in the trade permit list already
   caused weeks of 500s on every API trade creation (GO-180). Overrides that
   only *add* to an upstream list must not restate that list.
6. Sanity pass: `grep -rn '^<<<<<<<' .` (no leftovers), `git log --oneline
   <target>..HEAD` matches the original fork-commit list, `ls db/migrate`
   has both the new upstream migrations and the fork's own.
   - **Regenerating `db/schema.rb` (GO-203, recurred in v0.7.4):** plain
     `bin/rails db:migrate` on a *virgin* database schema-loads the existing
     `schema.rb` instead of running pending migrations (`initialize_database`
     shortcut) — it records every migration as applied without executing them,
     so fork tables silently vanish. Correct procedure: run migrations directly
     via a runner (`ActiveRecord::MigrationContext.new(
     ActiveRecord::Migrator.migrations_paths)` → `ctx.up(nil)`), then
     `bin/rails db:schema:dump`, and verify fork tables exist before dumping.
   - Local validation runs on Docker (host has no usable Ruby): throwaway
     `ruby:3.4.9` container with `-v "$PWD":/app -e BUNDLE_PATH=/bundle -v
     sure_bundle_cache:/bundle` + disposable postgres:16/redis containers on a
     shared docker network (`DB_HOST=<pg-container>`). Full suite ≈ 90s.
7. `git push -u origin upstream-sync/<target>` (plain branch, doesn't
7. `git push -u origin upstream-sync/<target>` (plain branch, doesn't
   trigger the build). Let the user review/test before going further.
8. Once approved: `git checkout main && git reset --hard
   upstream-sync/<target> && git push --force-with-lease origin main` —
   triggers the GHCR build → dispatch to `sure-deploy` → VM deploy.
9. Verify: `gh run watch <run-id> --repo shebetov/sure`, then the
   corresponding run in `shebetov/sure-deploy`, then SSH the VM and check
   `docker compose logs web worker` for migration/boot errors. Then smoke
   test the overridden endpoints, which no boot check covers: create and
   delete a trade, POST `security_prices/upsert`, GET `exchange_rate`.
10. Rollback if needed: `git reset --hard backup/pre-<target>-sync && git
   push --force-with-lease origin main`, then let the redeploy cycle run.
