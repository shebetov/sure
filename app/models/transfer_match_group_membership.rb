class TransferMatchGroupMembership < ApplicationRecord
  belongs_to :transfer_match_group
  belongs_to :account

  validates :account_id, uniqueness: { scope: :transfer_match_group_id }

  validate :account_belongs_to_family

  private

    def account_belongs_to_family
      return unless account && transfer_match_group
      errors.add(:account, :invalid) unless account.family_id == transfer_match_group.family_id
    end
end
