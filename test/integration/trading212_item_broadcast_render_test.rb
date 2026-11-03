require "test_helper"

class Trading212ItemBroadcastRenderTest < ActiveSupport::TestCase
  # Trading212Item::SyncCompleteEvent#broadcast re-renders this partial from the
  # sync job, outside any request, so Current.user is nil there. A
  # viewer-dependent filter in the partial would raise on every completed sync
  # and take the whole family-wide broadcast down with it.
  test "the connection card still renders its accounts with no current user" do
    item = trading212_items(:configured_item)
    AccountProvider.create!(provider: trading212_accounts(:main_account), account: accounts(:investment))
    account = item.accounts.first
    assert account.present?, "fixture item needs at least one account"

    Current.reset
    assert_nil Current.user

    html = ApplicationController.render(
      partial: "trading212_items/trading212_item",
      locals: { trading212_item: item }
    )

    assert_includes html, account.name
  end
end
