class InvestmentsFullStatement
  HoldingRow = Data.define(:name, :ticker, :qty, :open_price, :current_price, :current_value, :cost_basis_value, :unrealized_pnl, :pnl_percent)
  Result = Data.define(:holdings, :total_value, :total_cost_basis, :total_unrealized_pnl, :family_currency, :has_partial_cost_basis)

  attr_reader :family, :user

  def initialize(family, user: nil)
    @family = family
    @user = user || Current.user
  end

  def breakdown
    return empty_result if crypto_account_ids.empty?

    holdings = current_holdings.to_a
    cash_value = cash_balance
    return empty_result if holdings.empty? && cash_value.zero?

    has_partial = false

    rows = holdings.group_by(&:security_id).map do |_security_id, holding_list|
      security = holding_list.first.security
      qty = holding_list.sum(&:qty)
      current_val = holding_list.sum { |h| convert_to_family_currency(h.amount, h.currency) }

      cost_basis_values = holding_list.map do |h|
        next nil if h.avg_cost.nil?
        convert_to_family_currency(h.qty * h.avg_cost.amount, h.currency)
      end

      if cost_basis_values.any?(&:nil?)
        has_partial = true
        cost_basis_total = nil
        unrealized_pnl = nil
        pnl_percent = nil
      else
        cost_basis_total = cost_basis_values.sum
        unrealized_pnl = current_val - cost_basis_total
        pnl_percent = cost_basis_total.positive? ? (unrealized_pnl / cost_basis_total) * 100 : nil
      end

      avg_cost_money = holding_list.first.avg_cost
      current_price_money = holding_list.first.price

      HoldingRow.new(
        name: security.name.presence || security.ticker,
        ticker: security.ticker,
        qty: qty,
        open_price: avg_cost_money,
        current_price: current_price_money ? Money.new(current_price_money, holding_list.first.currency) : nil,
        current_value: Money.new(current_val, family.currency),
        cost_basis_value: cost_basis_total ? Money.new(cost_basis_total, family.currency) : nil,
        unrealized_pnl: unrealized_pnl ? Money.new(unrealized_pnl, family.currency) : nil,
        pnl_percent: pnl_percent
      )
    end

    # P&L totals are computed from holdings only (cash has no cost basis / gain)
    # before the Cash row is appended, so cash doesn't dilute the P&L percent.
    all_known = rows.all? { |r| r.cost_basis_value }
    total_cost_basis = all_known ? rows.sum { |r| r.cost_basis_value.amount } : nil
    total_unrealized_pnl = total_cost_basis ? rows.sum { |r| r.current_value.amount } - total_cost_basis : nil

    if cash_value.nonzero?
      rows << HoldingRow.new(
        name: "Cash",
        ticker: family.currency,
        qty: nil,
        open_price: nil,
        current_price: nil,
        current_value: Money.new(cash_value, family.currency),
        cost_basis_value: Money.new(cash_value, family.currency),
        unrealized_pnl: Money.new(0, family.currency),
        pnl_percent: 0
      )
    end

    total_value = rows.sum { |r| r.current_value.amount }

    Result.new(
      holdings: rows.sort_by { |r| -r.current_value.amount },
      total_value: Money.new(total_value, family.currency),
      total_cost_basis: total_cost_basis ? Money.new(total_cost_basis, family.currency) : nil,
      total_unrealized_pnl: total_unrealized_pnl ? Money.new(total_unrealized_pnl, family.currency) : nil,
      family_currency: family.currency,
      has_partial_cost_basis: has_partial
    )
  end

  private
    def empty_result
      Result.new(
        holdings: [],
        total_value: Money.new(0, family.currency),
        total_cost_basis: nil,
        total_unrealized_pnl: nil,
        family_currency: family.currency,
        has_partial_cost_basis: false
      )
    end

    def current_holdings
      Holding
        .where(account_id: crypto_account_ids)
        .where.not(qty: 0)
        .where(
          id: Holding
            .where(account_id: crypto_account_ids)
            .select("DISTINCT ON (holdings.account_id, holdings.security_id) holdings.id")
            .order(Arel.sql("holdings.account_id, holdings.security_id, holdings.date DESC"))
        )
        .includes(:security)
    end

    def crypto_accounts
      @crypto_accounts ||= begin
        scope = family.accounts.visible.where(accountable_type: %w[Investment Crypto])
        scope = scope.included_in_finances_for(user) if user
        scope.to_a
      end
    end

    def crypto_account_ids
      @crypto_account_ids ||= crypto_accounts.map(&:id)
    end

    def cash_balance
      crypto_accounts.sum { |a| convert_to_family_currency(a.cash_balance, a.currency) }
    end

    def exchange_rates
      @exchange_rates ||= begin
        holding_currencies = Holding.where(account_id: crypto_account_ids).distinct.pluck(:currency)
        foreign = (crypto_accounts.map(&:currency) + holding_currencies)
          .compact.uniq.reject { |c| c == family.currency }
        ExchangeRate.rates_for(foreign, to: family.currency, date: Date.current)
      end
    end

    def convert_to_family_currency(amount, from_currency)
      numeric = amount.is_a?(Money) ? amount.amount : amount
      return numeric if from_currency == family.currency
      rate = exchange_rates[from_currency] || 1
      numeric * rate
    end
end
