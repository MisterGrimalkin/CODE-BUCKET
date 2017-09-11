require_relative 'utils'

class Account

  def initialize(path)
    @statements = {}
    @categories = {}
    cat_file = "#{path}/config/categories.csv"
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

  def monthly_breakdown(opts)

    transactions = search_transactions(opts)
    result = {}
    all_categories = {credit: [], debit: []}

    transactions.each do |t|

      month = Date.civil(t[:date].year, t[:date].month, 1)

      unless result[month]
        result[month] = {credit: {}, debit: {}, total_credit: 0.0, total_debit: 0.0}
      end

      unless result[month][:last_balance] && result[month][:last_balance_date] >= t[:date]
        result[month][:last_balance] = t[:balance]
        result[month][:last_balance_date] = t[:date]
      end

      type = t[:credit] > 0 ? :credit : :debit
      totals_type = t[:credit] > 0 ? :total_credit : :total_debit

      data = result[month]
      cat = t[:category]
      unless data[type][cat]
        data[type][cat] = 0.0
      end
      data[type][cat] += t[type]
      data[totals_type] += t[type]

      unless all_categories[type].include? cat
        all_categories[type] << cat
      end

    end

    return result, all_categories
  end

  def search_transactions(opts)

    from, to, category, description, mode, min, max, exact, match_case =
        opts[:from], opts[:to],
            opts[:category],
            opts[:description],
            opts[:mode], opts[:min], opts[:max], opts[:exact], opts[:case]
    transactions = []

    @statements.each do |date, statement|
      statement.all_transactions.each do |t|
        if (!from || t[:date] >= from) &&
            (!to || t[:date] <= to) &&
            (!category || match_any?(t[:category],
                                     category.split(','), exact, match_case)) &&
            (!description || match_any?(t[:description],
                                        description.split(','), exact, match_case)) &&
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