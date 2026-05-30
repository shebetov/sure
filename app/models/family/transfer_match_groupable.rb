module Family::TransferMatchGroupable
  def transfer_match_candidates(date_window: transfer_match_date_window,
                                exchange_rate_tolerance: transfer_match_exchange_rate_tolerance,
                                **kwargs)
    scope = super(date_window: date_window, exchange_rate_tolerance: exchange_rate_tolerance, **kwargs)
    return scope unless transfer_match_groups.exists?

    scope.where(
      "EXISTS (
        SELECT 1 FROM transfer_match_group_memberships m1
        JOIN transfer_match_group_memberships m2 ON m1.transfer_match_group_id = m2.transfer_match_group_id
        WHERE m1.account_id = inflow_candidates.account_id
        AND m2.account_id = outflow_candidates.account_id
      )"
    )
  end
end
