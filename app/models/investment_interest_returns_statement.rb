class InvestmentInterestReturnsStatement
  MIN_ANNUALIZE_DAYS = 30

  AccountArr = Data.define(:account, :interest, :avg_balance, :arr)
  Result = Data.define(:accounts, :total_interest, :total_avg_balance, :total_arr, :annualized)

  attr_reader :family, :user

  def initialize(family, user: nil)
    @family = family
    @user = user || Current.user
  end

  def interest_arr(period: Period.current_month)
    return empty_result if investment_account_ids.empty?

    interest = interest_by_account(period)
    balances = avg_balance_by_account(period)
    days = period.days
    annualize = days >= MIN_ANNUALIZE_DAYS
    factor = days.positive? ? 365.0 / days : 0

    rows = investment_accounts.filter_map do |account|
      earned = convert_to_family_currency(interest[account.id].to_d.abs, account.currency)
      next if earned <= 0

      avg = convert_to_family_currency(balances[account.id].to_d, account.currency)
      arr = (annualize && avg.positive?) ? (earned / avg) * factor : nil

      AccountArr.new(
        account: account,
        interest: Money.new(earned, family.currency),
        avg_balance: Money.new(avg, family.currency),
        arr: arr
      )
    end

    total_interest = rows.sum { |r| r.interest.amount }
    total_avg = rows.sum { |r| r.avg_balance.amount }
    total_arr = (annualize && total_avg.positive?) ? (total_interest / total_avg) * factor : nil

    Result.new(
      accounts: rows.sort_by { |r| -(r.arr || -Float::INFINITY) },
      total_interest: Money.new(total_interest, family.currency),
      total_avg_balance: Money.new(total_avg, family.currency),
      total_arr: total_arr,
      annualized: annualize
    )
  end

  private
    def empty_result
      Result.new(
        accounts: [],
        total_interest: Money.new(0, family.currency),
        total_avg_balance: Money.new(0, family.currency),
        total_arr: nil,
        annualized: false
      )
    end

    def interest_by_account(period)
      family.transactions
        .visible
        .where(investment_activity_label: "Interest")
        .where(entries: { date: period.date_range, account_id: investment_account_ids })
        .group("entries.account_id")
        .sum("entries.amount")
    end

    def avg_balance_by_account(period)
      Balance
        .where(account_id: investment_account_ids, date: period.date_range)
        .group(:account_id)
        .average(:end_balance)
    end

    def investment_accounts
      @investment_accounts ||= begin
        scope = family.accounts.visible.where(accountable_type: %w[Investment Crypto])
        scope = scope.included_in_finances_for(user) if user
        scope.to_a
      end
    end

    def investment_account_ids
      @investment_account_ids ||= investment_accounts.map(&:id)
    end

    def exchange_rates
      @exchange_rates ||= begin
        foreign = investment_accounts.map(&:currency).compact.uniq.reject { |c| c == family.currency }
        ExchangeRate.rates_for(foreign, to: family.currency, date: Date.current)
      end
    end

    def convert_to_family_currency(amount, from_currency)
      return amount if from_currency == family.currency
      rate = exchange_rates[from_currency] || 1
      amount * rate
    end
end
