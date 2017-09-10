class Account

  def initialize(path)
    @statements = {}
    @categories = {}
    cat_file = "#{ENV['HOME']}/data/Finances/Statements/config/categories.csv"
    if File.exist? cat_file
      CSV.parse(File.read(cat_file)) do |row|
        @categories[row[0]] = row[1]
      end
    end
    Dir.glob("#{path}/*csv").each do |file|
      statement = Statement.new(file, @categories)
      if @statements[statement.start_date]
        raise Exception.new("Duplicate statement!")
      end
      @statements[statement.start_date] = statement
    end
  end

  attr_reader :statements
  attr_reader :categories

  def totals_by_description(type)
    totals = {}
    @statements.each do |date, statement|
      statement.transactions(type).each do |t|
        unless totals[t[:description]]
          totals[t[:description]] = {amount: 0.0, category: t[:category]}
        end
        totals[t[:description]][:amount] += t[type]
      end
    end
    totals.sort_by { |k, v| v[0] }.reverse
  end

  def totals_by_category(type)
    totals = {}
    @statements.each do |date, statement|
      statement.transactions(type).each do |t|
        unless totals[t[:category]]
          totals[t[:category]] = {amount: 0.0}
        end
        totals[t[:category]][:amount] += t[type]
      end
    end
    totals.sort_by { |k, v| v[0] }.reverse
  end

  def sum_totals(transactions)
    credit = 0.0
    debit = 0.0
    count = 0
    transactions.each do |t|
      credit += t[:credit]
      debit += t[:debit]
      count += 1
    end
    {credit: credit, debit: debit, count: count}
  end

  def category_totals(transactions)
    totals = {}
    transactions.each do |t|
      unless totals[t[:category]]
        totals[t[:category]] = {credit: 0.0, debit: 0.0}
      end
      totals[t[:category]][:credit] += t[:credit]
      totals[t[:category]][:debit] += t[:debit]
    end
    totals.sort_by { |k, v| v[:debit] }.reverse
  end

  def monthly_breakdown(transactions)
    totals = {}
    all_categories = {credit: [], debit: []}
    transactions.each do |t|
      month = Date.civil(t[:date].year, t[:date].month, 1)
      unless totals[month]
        totals[month] = {credit: {}, debit: {}, total_credit: 0.0, total_debit: 0.0}
      end

      if totals[month][:last_balance]
        if totals[month][:last_balance_date] < t[:date]
          totals[month][:last_balance] = t[:balance]
          totals[month][:last_balance_date] = t[:date]
        end
      else
        totals[month][:last_balance] = t[:balance]
        totals[month][:last_balance_date] = t[:date]
      end

      if t[:credit] > 0
        type = :credit
        totals_type = :total_credit
      else
        type = :debit
        totals_type = :total_debit
      end

      data = totals[month]
      unless data[type][t[:category]]
        data[type][t[:category]] = 0.0
      end
      unless all_categories[type].include? t[:category]
        all_categories[type] << t[:category]
      end
      data[type][t[:category]] += t[type]
      data[totals_type] += t[type]
    end
    return totals, all_categories
  end

  def search_transactions(from, to, category, description, mode, min, max)
    transactions = []
    @statements.each do |date, statement|
      statement.all_transactions.each do |t|
        if (!from || t[:date] >= from) &&
            (!to || t[:date] <= to) &&
            (!category || t[:category].downcase.include?(category.downcase)) &&
            (!description || t[:description].downcase.include?(description.downcase)) &&
            (!mode ||
                (mode==:credit && t[:credit] > 0) ||
                (mode==:debit && t[:debit] > 0)
            ) &&
            (!min ||
                (t[:credit]==0 && t[:debit] >= min) ||
                (t[:debit]==0 && t[:credit] >= min)
            ) &&
            (!max ||
                (t[:credit]==0 && t[:debit] <= max) ||
                (t[:debit]==0 && t[:credit] <= max)
            )
          transactions << t
        end
      end
    end
    transactions.sort_by { |t| t[:date] }
  end

end