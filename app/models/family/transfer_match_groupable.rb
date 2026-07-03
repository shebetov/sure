module Family::TransferMatchGroupable
  def transfer_match_candidates(date_window: transfer_match_date_window,
                                exchange_rate_tolerance: transfer_match_exchange_rate_tolerance,
                                **kwargs)
    candidates = super(date_window: date_window, exchange_rate_tolerance: exchange_rate_tolerance, **kwargs)
    return candidates unless transfer_match_groups.exists?

    transaction_ids = candidates.flat_map { |c| [c.inflow_transaction_id, c.outflow_transaction_id] }.uniq
    transactions_by_id = Transaction.includes(entry: :account).where(id: transaction_ids).index_by(&:id)

    account_to_groups = TransferMatchGroupMembership
      .where(transfer_match_group: transfer_match_groups)
      .group_by(&:account_id)
      .transform_values { |memberships| memberships.map(&:transfer_match_group_id).uniq }

    candidates.select do |candidate|
      inflow_txn = transactions_by_id[candidate.inflow_transaction_id]
      outflow_txn = transactions_by_id[candidate.outflow_transaction_id]
      next false unless inflow_txn && outflow_txn

      inflow_groups = account_to_groups[inflow_txn.entry.account_id] || []
      outflow_groups = account_to_groups[outflow_txn.entry.account_id] || []
      (inflow_groups & outflow_groups).any?
    end
  end
end
