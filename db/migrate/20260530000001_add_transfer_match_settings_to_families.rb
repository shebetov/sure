class AddTransferMatchSettingsToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :transfer_match_date_window, :integer, null: false, default: 4
    add_column :families, :transfer_match_exchange_rate_tolerance, :decimal, precision: 5, scale: 3, null: false, default: 0.1
  end
end
