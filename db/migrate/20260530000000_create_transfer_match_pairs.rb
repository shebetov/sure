class CreateTransferMatchPairs < ActiveRecord::Migration[7.2]
  def change
    create_table :transfer_match_pairs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :account_a, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :account_b, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.timestamps
    end

    add_index :transfer_match_pairs, [ :family_id, :account_a_id, :account_b_id ], unique: true, name: "index_transfer_match_pairs_unique"
  end
end
