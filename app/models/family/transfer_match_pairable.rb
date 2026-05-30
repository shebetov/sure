module Family::TransferMatchPairable
  def transfer_match_candidates(*args, **kwargs)
    scope = super
    return scope unless transfer_match_pairs.exists?

    pairs = transfer_match_pairs.pluck(:account_a_id, :account_b_id)
    clause = pairs.map do
      "(inflow_candidates.account_id = ? AND outflow_candidates.account_id = ?) OR " \
      "(inflow_candidates.account_id = ? AND outflow_candidates.account_id = ?)"
    end.join(" OR ")
    binds = pairs.flat_map { |a, b| [ a, b, b, a ] }

    scope.where(clause, *binds)
  end
end
