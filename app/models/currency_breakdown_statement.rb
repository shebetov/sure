class CurrencyBreakdownStatement
  CurrencyRow = Data.define(:currency, :account_count, :native_total, :converted_total, :percentage)
  Result = Data.define(:currencies, :total, :family_currency)

  attr_reader :family, :user

  def initialize(family, user: nil)
    @family = family
    @user = user || Current.user
  end

  def breakdown
    return empty_result if accounts.empty?

    grouped = accounts.group_by(&:currency)

    rows = grouped.map do |currency, currency_accounts|
      native_total = currency_accounts.sum { |account| signed_balance(account) }
      converted_total = convert_to_family_currency(native_total, currency)

      CurrencyRow.new(
        currency: currency,
        account_count: currency_accounts.size,
        native_total: Money.new(native_total, currency),
        converted_total: Money.new(converted_total, family.currency),
        percentage: nil
      )
    end

    total = rows.sum { |row| row.converted_total.amount }
    base = rows.sum { |row| row.converted_total.amount.abs }

    rows = rows.map do |row|
      percentage = base.positive? ? (row.converted_total.amount.abs / base) * 100 : 0
      row.with(percentage: percentage)
    end

    Result.new(
      currencies: rows.sort_by { |row| -row.converted_total.amount },
      total: Money.new(total, family.currency),
      family_currency: family.currency
    )
  end

  private
    def empty_result
      Result.new(currencies: [], total: Money.new(0, family.currency), family_currency: family.currency)
    end

    def signed_balance(account)
      account.classification == "liability" ? -account.balance : account.balance
    end

    def accounts
      @accounts ||= begin
        scope = family.accounts.visible.where.not(accountable_type: "Vehicle")
        scope = scope.included_in_finances_for(user) if user
        scope.to_a
      end
    end

    def exchange_rates
      @exchange_rates ||= begin
        foreign = accounts.map(&:currency).compact.uniq.reject { |c| c == family.currency }
        ExchangeRate.rates_for(foreign, to: family.currency, date: Date.current)
      end
    end

    def convert_to_family_currency(amount, from_currency)
      return amount if from_currency == family.currency
      rate = exchange_rates[from_currency] || 1
      amount * rate
    end
end
