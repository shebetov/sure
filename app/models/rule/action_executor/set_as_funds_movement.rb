class Rule::ActionExecutor::SetAsFundsMovement < Rule::ActionExecutor
  def label
    "Mark as transfer (no counterpart)"
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false, rule_run: nil)
    scope = transaction_scope.with_entry

    count_modified_resources(scope) do |txn|
      next false if txn.transfer?
      txn.enrich_attribute(:kind, "funds_movement", source: "rule")
    end
  end
end
