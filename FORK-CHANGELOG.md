# Fork Changelog (customizations)

1. **Group-scoped transfer matching** — accounts only auto-match within configured groups; the greedy matcher picks the closest-date pair across all accounts in the same group
2. **Per-family tuning knobs** — configurable date window and FX tolerance (defaults match upstream)
3. **Settings UI** — `/settings/transfer_match_groups` to manage groups and tuning
4. **Transfer detail panel** — shows each transaction's name and a "View transaction" link for both sides of a transfer
5. **Transfer match filter** — transactions page filter to show only auto-matched (pending) or confirmed transfer transactions
6. **Self-hosted build pipeline** — arm64 image to GHCR, auto-deploys via `sure-deploy`
7. **Rule enrichment ignores locks** — `enrich_attributes` skips the locked-attribute check when `source == "rule"`, so rules always apply even to manually-categorized transactions
