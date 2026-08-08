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
5. Re-diff `sure-deploy/config/api_overrides.rb` against the upstream methods
   it copies (`Api::V1::TradesController#trade_params`, security-prices and
   exchange-rates controllers). It redefines whole methods via `class_eval`,
   so upstream edits to them are silently discarded — git reports nothing,
   the app boots fine. An omitted `:type` in the trade permit list already
   caused weeks of 500s on every API trade creation (GO-180). Overrides that
   only *add* to an upstream list must not restate that list.
6. Sanity pass: `grep -rn '^<<<<<<<' .` (no leftovers), `git log --oneline
   <target>..HEAD` matches the original fork-commit list, `ls db/migrate`
   has both the new upstream migrations and the fork's own. Don't hand-edit
   `db/schema.rb` — `bin/docker-entrypoint` runs `db:prepare` on container
   boot, so a stale schema.rb isn't a deploy blocker.
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
