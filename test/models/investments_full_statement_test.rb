require "test_helper"

class InvestmentsFullStatementTest < ActiveSupport::TestCase
  setup do
    @family = families(:empty)
    @user = users(:empty)
    @security = Security.create!(ticker: "WIDG", name: "Widget Co")
  end

  test "a security held in several accounts shows qty-weighted open and current prices" do
    hold(account("Broker A"), qty: 1, price: 100, cost_basis: 50)
    hold(account("Broker B"), qty: 3, price: 100, cost_basis: 90)

    row = InvestmentsFullStatement.new(@family, user: @user).breakdown.holdings.sole

    assert_equal 4, row.qty
    assert_equal Money.new(80, "USD"), row.open_price
    assert_equal Money.new(100, "USD"), row.current_price
    assert_equal Money.new(320, "USD"), row.cost_basis_value
    assert_equal Money.new(80, "USD"), row.unrealized_pnl
  end

  private
    def account(name)
      @family.accounts.create!(owner: @user, name: name, balance: 0, currency: "USD", accountable: Investment.new)
    end

    def hold(account, qty:, price:, cost_basis:)
      account.holdings.create!(
        security: @security, date: Date.current, qty: qty, price: price,
        amount: qty * price, currency: "USD", cost_basis: cost_basis
      )
    end
end
