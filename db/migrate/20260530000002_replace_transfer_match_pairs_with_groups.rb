class ReplaceTransferMatchPairsWithGroups < ActiveRecord::Migration[7.2]
  def change
    drop_table :transfer_match_pairs

    create_table :transfer_match_groups, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.timestamps
    end

    create_table :transfer_match_group_memberships, id: :uuid do |t|
      t.references :transfer_match_group, null: false, foreign_key: true, type: :uuid
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :transfer_match_group_memberships, [ :transfer_match_group_id, :account_id ], unique: true,
              name: :idx_transfer_match_group_memberships_unique
  end
end
