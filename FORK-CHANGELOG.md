# Fork Changelog (customizations)

1. **Group-scoped transfer matching** — accounts only auto-match within configured groups; the greedy matcher picks the closest-date pair across all accounts in the same group
2. **Per-family tuning knobs** — configurable date window and FX tolerance (defaults match upstream)
3. **Settings UI** — `/settings/transfer_match_groups` to manage groups and tuning
4. **Transfer detail panel** — shows each transaction's name and a "View transaction" link for both sides of a transfer
5. **Transfer match filter** — transactions page filter to show only auto-matched (pending) or confirmed transfer transactions
6. **Self-hosted build pipeline** — arm64 image to GHCR, auto-deploys via `sure-deploy`
7. **Rule enrichment ignores locks** — `enrich_attributes` skips the locked-attribute check when `source == "rule"`, and `family/syncer.rb` passes `ignore_attribute_locks: true` so the DB-level scope filter is also bypassed on sync; rules always apply even to manually-categorized transactions
8. **API: `kind` filter and update** — `GET /api/v1/transactions?kind=…` and `PATCH`/`POST /api/v1/transactions` with `kind` now supported; used by the provider-sync scripts to set native kinds at creation (`Contribution → investment_contribution`, `Withdrawal → funds_movement`). We follow stock Sure P&L semantics — there is no `kind`-reclassification housekeeping.
9. **Batch account sync after rule transfer creation** — `SetAsTransferOrPayment` now collects affected accounts and calls `sync_later` once per unique account after all transfers are built, instead of once per transaction, preventing N×2 sync explosions when rules apply to many transactions
10. **AI auto-categorization uses only subcategories** — `Family::AutoCategorizer` filters to subcategories only (`select(&:subcategory?)`), preventing assignment to parent/group categories
