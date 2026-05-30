class TransferMatchPair < ApplicationRecord
  belongs_to :family
  belongs_to :account_a, class_name: "Account"
  belongs_to :account_b, class_name: "Account"

  validate :accounts_belong_to_family
  validate :accounts_are_different
  before_validation :normalize_account_order

  private

    def normalize_account_order
      return unless account_a_id.present? && account_b_id.present?
      if account_a_id > account_b_id
        self.account_a_id, self.account_b_id = account_b_id, account_a_id
      end
    end

    def accounts_belong_to_family
      return unless family_id.present?
      if account_a_id.present? && !family.account_ids.include?(account_a_id)
        errors.add(:account_a, :invalid)
      end
      if account_b_id.present? && !family.account_ids.include?(account_b_id)
        errors.add(:account_b, :invalid)
      end
    end

    def accounts_are_different
      if account_a_id.present? && account_a_id == account_b_id
        errors.add(:account_b, :must_be_different)
      end
    end
end
