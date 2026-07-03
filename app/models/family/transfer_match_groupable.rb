module Family::TransferMatchGroupable
  def transfer_match_candidates(date_window: transfer_match_date_window,
                                exchange_rate_tolerance: transfer_match_exchange_rate_tolerance,
                                **kwargs)
    candidates = super(date_window: date_window, exchange_rate_tolerance: exchange_rate_tolerance, **kwargs)
    return candidates unless transfer_match_groups.exists?

    transaction_ids = candidates.flat_map { |c| [c.inflow_transaction_id, c.outflow_transaction_id] }.uniq
    transactions_by_id = Transaction.includes(entry: :account).where(id: transaction_ids).index_by(&:id)
    group_memberships = transfer_match_group_memberships.index_by(&:account_id)

    candidates.select do |candidate|
      inflow_txn = transactions_by_id[candidate.inflow_transaction_id]
      outflow_txn = transactions_by_id[candidate.outflow_transaction_id]
      next false unless inflow_txn && outflow_txn

      inflow_group = group_memberships[inflow_txn.entry.account_id]&.transfer_match_group_id
      outflow_group = group_memberships[outflow_txn.entry.account_id]&.transfer_match_group_id
      inflow_group.present? && inflow_group == outflow_group
    end
  end
end
