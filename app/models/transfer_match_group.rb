class TransferMatchGroup < ApplicationRecord
  belongs_to :family
  has_many :transfer_match_group_memberships, dependent: :destroy
  has_many :accounts, through: :transfer_match_group_memberships
end
