require_relative 'account'
require_relative 'statement'
require_relative 'report_column'
require_relative 'printer'

# Load data
current_account = Account.new("#{ENV['HOME']}/data/Finances/Statements")

# Process parameters
search = {}
report_mode = false
sheet_mode = false
ignore = 0

if ARGV.size == 0

  # Print balance
  last_transaction =
      current_account
          .statements
          .sort_by { |date, statement| date }
          .last[1]
          .all_transactions
          .first
  puts "Balance #{last_transaction[:date].strftime('%d %B %Y')}: #{last_transaction[:balance]}"

elsif ARGV[0]=='export'

  # Export all categories
  current_account.totals_by_description(:credit).sort_by { |k, v| v[:category] }.each do |k, v|
    puts "#{k},#{v[:category]}"
  end
  current_account.totals_by_description(:debit).sort_by { |k, v| v[:category] }.each do |k, v|
    puts "#{k},#{v[:category]}"
  end

else

  # Process arguments
  ARGV.each_with_index do |arg, i|

    if ignore == 0
      case arg.downcase

        when 'help', '?'
          puts BAR_1
          puts "Options:"
          puts "  report [Y1] [Y2] : yearly analysis CSV years Y1 to Y2, or current"
          puts "  month [M] [Y]    : transactions in month M & year Y, or current"
          puts "  from YYYY-MM-DD  : transactions on or after date"
          puts "  to YYYY-MM-DD    : transactions on or before date"
          puts "  min VALUE        : only transactions of at least VALUE"
          puts "  max VALUE        : only transactions of at most VALUE"
          puts "  credit           : only credit (income) transactions"
          puts "  debit            : only debit (outgoing) transactions"
          puts "  category CAT     : transactions with specified categories (comma-separated)"
          puts "  description DSC  : transactions with specified descriptions (comma-separated)"
          puts "  exact            : whole-word match on category and description"
          puts "  case             : case-sensitive match on category and description"
          puts "  sheet            : spreadsheet output mode"
          puts BAR_1
          exit

        when 'report'
          report_mode = true
          search[:from] = Date.civil(Date.today.year, 1, 1)
          search[:to] = Date.civil(Date.today.year, 12, 31)
          if i+1 < ARGV.size
            search[:from] = ARGV[i+1]!='-' ? Date.parse("#{ARGV[i+1]}-01-01") : search[:from]
            ignore = 1
            if i+2 < ARGV.size
              search[:to] = ARGV[i+2]!='-' ? Date.parse("#{ARGV[i+2]}-12-31") : search[:to]
              ignore = 2
            else
              search[:to] = Date.civil(date[:from].year, 12, 31)
            end
          end

        when 'month'
          unless search[:from] || search[:to]
            month = Date.today.month
            year = Date.today.year
            if i+1 < ARGV.size
              month = ARGV[i+1]!='-' ? ARGV[i+1] : month
              ignore = 1
              if i+2 < ARGV.size
                year = ARGV[i+2]!='-' ? ARGV[i+2] : year
                ignore = 2
              end
            end
            search[:from] = Date.parse("#{year}-#{month}-01")
            search[:to] = Date.civil(search[:from].year, search[:from].month, -1)
          end

        when 'from', 'after', 'since'
          unless search[:from] || i+1 > ARGV.size
            search[:from] = Date.parse(ARGV[i+1])
            ignore = 1
          end

        when 'to', 'before', 'until'
          unless search[:to] || i+1 > ARGV.size
            search[:to] = Date.parse(ARGV[i+1])
            ignore = 1
          end

        when 'category', 'cat'
          unless search[:category] || i+1 > ARGV.size
            search[:category] = ARGV[i+1]
            ignore = 1
          end

        when 'description', 'desc'
          unless search[:description] || i+1 > ARGV.size
            search[:description] = ARGV[i+1]
            ignore = 1
          end

        when 'exact'
          search[:exact] = true

        when 'case'
          search[:case] = true

        when 'credit', 'income', 'in'
          unless search[:mode]
            search[:mode] = :credit
          end

        when 'debit', 'outgoing', 'out'
          unless search[:mode]
            search[:mode] = :debit
          end

        when 'above', 'over', 'min'
          unless search[:min] || i+1 > ARGV.size
            search[:min] = ARGV[i+1].to_f
            ignore = 1
          end

        when 'below', 'under', 'max'
          unless search[:max] || i+1 > ARGV.size
            search[:max] = ARGV[i+1].to_f
            ignore = 1
          end

        when 'sheet'
          sheet_mode = true

        else
          abort "Unknown option '#{arg}'"
      end
    else
      ignore -= 1
    end
  end

  if search[:from] && search[:to] && search[:to] < search[:from]
    abort "Invalid date range"
  end

  if search[:min] && search[:max] && search[:max] < search[:min]
    abort "Invalid value range"
  end

  # Do search
  if sheet_mode

    transactions, category_map = current_account.search_transactions(search, true)

    from = search[:from] || transactions.first[:date]
    to = search[:to] || transactions.last[:date]

    summary = ',CATEGORY'
    detail = 'CATEGORY,DESCRIPTION'
    descriptions = {}
    columns = []
    (to - from).to_i.times do |i|
      column = ReportColumn.new(from+i)
      column.take_transactions transactions
      summary << ",#{from+i}"
      detail << ",#{from+i}"
      columns << column
    end
    summary << "\n"
    detail << "\n"

    category_map.each do |cat, descs|
      summary << ",#{cat}"
      columns.each do |column|
        summary << ",#{column.total(cat)}"
      end
      first = true
      descs.each do |desc|
        detail << "#{first ? cat : ''},#{desc}"
        first = false
        columns.each do |column|
          detail << ",#{column.amount(cat, desc)}"
        end
        detail << "\n"
      end
      summary << "\n"
    end

    puts summary
    puts detail



    # # CAT => {DESC => {DATE => TOTAL_AMOUNT}}
    # amounts = {}
    #
    # # CAT => {DATE => CAT_TOTAL}
    # cat_amounts = {}
    #
    # transactions.each do |t|
    #   descs = (amounts[t[:category]] = amounts[t[:category]] || {})
    #   dates = (descs[t[:description]] = descs[t[:description]] || {})
    #   total = (dates[t[:date].to_s] || 0.0)
    #   dates[t[:date].to_s] = total + t[:credit] - t[:debit]
    #   cat_total = cat_amounts[t[:category]] = cat_amounts[t[:category]] || {}
    #
    # end
    # output = {}
    # amounts.sort_by { |k, _| k }.each { |k, v| output[k]=v }
    #
    # from = search[:from] || transactions.first[:date]
    # to = search[:to] || transactions.last[:date]
    #
    # header = ',,TOTAL'
    # (to - from).to_i.times do |i|
    #   header << ",#{(from+i).to_s}"
    # end
    #
    # rows = []
    # cat_totals = {}
    # output.each do |cat, descs|
    #   first_desc = true
    #   cat_total = 0.0
    #   descs.each do |desc, dates|
    #     row = ''
    #     total = 0.0
    #     (to - from).to_i.times do |i|
    #       amt = dates[(from+i).to_s] || 0.0
    #       row << ",#{sprintf('%.2f', amt)}"
    #       total += amt
    #       cat_total += amt
    #     end
    #     rows << "#{first_desc ? cat : ''},#{desc},#{sprintf('%.2f', total)}#{row}"
    #     first_desc = false
    #   end
    #   cat_totals[cat] = cat_total
    # end
    #
    # cat_totals.sort_by{|k,v|v}.reverse.each do |cat, total|
    #   puts "#{cat},#{sprintf('%.2f', total)}"
    # end
    # puts
    # puts header
    # puts rows

  elsif report_mode

    breakdown, categories = current_account.monthly_breakdown(search)
    debit_cats = categories[:debit].sort

    puts "Date,Balance,IN,OUT,#{debit_cats.join(',')}"
    breakdown.sort_by { |k, v| k }.each do |date, v|
      line = "#{date},#{curr(v[:last_balance])},#{curr(v[:total_credit])},#{curr(v[:total_debit])}"
      debit_cats.each do |cat|
        line << ",#{curr(v[:debit][cat])}"
      end
      puts line
    end

  else

    transactions = current_account.search_transactions(search)

    puts BAR_1
    print_transactions(transactions, sum_totals(transactions), category_totals(transactions))
    puts BAR_1

  end

end

=begin
show_detail = ARGV.include? "detail"

if ARGV[0]=='totals'

  current_account.totals_by_category(:debit).each do |k, v|
    puts "#{k},#{sprintf('%.2f', v[:amount])}"
  end

elsif ARGV[0]=='export-names'

  current_account.totals_by_description(:credit).each do |k, v|
    puts "#{k},#{v[:category]}"
  end
  current_account.totals_by_description(:debit).each do |k, v|
    puts "#{k},#{v[:category]}"
  end

elsif ARGV[0]=='nested'
  if ARGV[1] && ARGV[1]!='detail'
    single_statement = Statement.new("#{path}/#{ARGV[1]}.csv", current_account.categories)
    single_statement.print_start_date
    single_statement.print_nested_totals :credit, show_detail
    single_statement.print_nested_totals :debit, show_detail
  else
    current_account.statements.each do |date, statement|
      statement.print_start_date
      statement.print_nested_totals :credit, show_detail
      statement.print_nested_totals :debit, show_detail

    end
  end

else

  credits = 0.0
  debits = 0.0
  statements = current_account.statements
  statements.each do |date, statement|
    statement.monthly_totals show_detail
    credits += statement.total_credit
    debits += statement.total_debit
  end

  puts "-" * 50
  puts "TOTALS"
  puts "   INCOME:    #{sprintf('%.2f', credits).rjust(9, " ")}"
  puts "   OUTGOINGS: #{sprintf('%.2f', debits).rjust(9, " ")}"
  puts "   CASHFLOW   #{sprintf('%.2f', credits-debits).rjust(9, " ")}"

  puts "-" * 50
  puts "AVERAGES"
  puts "   INCOME:    #{sprintf('%.2f', credits/statements.size).rjust(9, " ")}"
  puts "   OUTGOINGS: #{sprintf('%.2f', debits/statements.size).rjust(9, " ")}"
  puts "   CASHFLOW   #{sprintf('%.2f', (credits-debits)/statements.size).rjust(9, " ")}"

end
=end
