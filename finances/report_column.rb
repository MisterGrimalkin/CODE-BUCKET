class ReportColumn

  def initialize(date)
    @date = date
    @transactions = []
    @totals = {}
    @income = 0.0
    @outgoings = 0.0
    @end_balance = 0.0
  end

  attr_accessor :date

  def take_transactions(transactions)
    transactions.each do |t|
      if t[:date] == @date
        @transactions << t
        @totals[t[:category]] ||= {}
        @totals[t[:category]][t[:description]] ||= 0.0
        @totals[t[:category]][t[:description]] += (t[:credit] - t[:debit])
        @income += t[:credit]
        @outgoings += t[:debit]
        @end_balance = t[:balance]
      end
    end
  end

  def amount(category, description)
    sprintf('%.2f', (@totals[category]||{})[description]||0.0)
  end

  def total(category)
    total = 0.0
    if (totals = @totals[category])
      totals.each do |_, amount|
        total += amount
      end
    end
    sprintf('%.2f', total)
  end

  def totals(category)
    inc, out = 0.0, 0.0
    if (totals = @totals[category])
      totals.each do |_, amount|
        if amount > 0
          inc += amount
        else
          out += -amount
        end
      end
    end
    [sprintf('%.2f', inc), sprintf('%.2f', iout)]
  end

  def income
    sprintf('%.2f', @income)
  end

  def outgoings
    sprintf('%.2f', @outgoings)
  end

  def cashflow
    sprintf('%.2f', @income - @outgoings)
  end

  def balance
    sprintf('%.2f', @end_balance)
  end

end