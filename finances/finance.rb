require_relative 'account'
require_relative 'statement'
require_relative 'printer'

path = "#{ENV['HOME']}/data/Finances/Statements"

current_account = Account.new("#{ENV['HOME']}/data/Finances/Statements")

# month august [2015]
# from 2017-01-01
# to 2017-08-01
# category ABC
# description DEF

ignore = 0
from_date = nil
to_date = nil
search_category = nil
search_description = nil
mode = nil
min_value = nil
max_value = nil
report = false

if ARGV.size == 0
  last_transaction =
      current_account
          .statements
          .sort_by { |date, statement| date }
          .last[1]
          .all_transactions
          .reverse
          .last
  puts "Balance as of #{last_transaction[:date].strftime('%d %B %Y')}: #{last_transaction[:balance]}"

elsif ARGV[0]=='export-names'

  current_account.totals_by_description(:credit).sort_by { |k, v| v[:category] }.each do |k, v|
    puts "#{k},#{v[:category]}"
  end
  current_account.totals_by_description(:debit).sort_by { |k, v| v[:category] }.each do |k, v|
    puts "#{k},#{v[:category]}"
  end

else
  ARGV.each_with_index do |arg, i|
    if ignore == 0
      case arg.downcase
        when 'report'
          report = true
          from_date = Date.civil(Date.today.year, 1, 1)
          to_date = Date.civil(Date.today.year, 12, 31)
          if i+1 < ARGV.size
            from_date = Date.parse("#{ARGV[i+1]}-01-01")
            to_date = Date.parse("#{ARGV[i+1]}-12-31")
            search_category = nil
            search_description = nil
            mode = nil
            min_value = nil
            max_value = nil
            ignore = ARGV.size
            if i+2 < ARGV.size
              to_date = Date.parse("31-12-#{ARGV[i+2]}")
            end
          end
          # puts "Monthly Breakdown: #{from_date.year} #{from_date.year == to_date.year ? '' : "- #{to_date.year}"}"
        when 'month'
          unless from_date || to_date
            month = Date.today.month
            year = Date.today.year
            if i+1 < ARGV.size
              month = ARGV[i+1]
              ignore = 1
              if i+2 < ARGV.size
                year = ARGV[i+2]
                ignore = 2
              end
            end
            from_date = Date.parse("01 #{month} #{year}")
            to_date = Date.civil(from_date.year, from_date.month, -1)
            puts "Month: #{from_date.strftime('%B')} #{from_date.strftime('%Y')} (#{from_date} to #{to_date})"
          end
        when 'from'
          unless from_date || i+1 > ARGV.size
            from_date = Date.parse(ARGV[i+1])
            ignore = 1
            puts "From: #{from_date.strftime('%d %B %Y')}"
          end
        when 'to'
          unless to_date || i+1 > ARGV.size
            to_date = Date.parse(ARGV[i+1])
            ignore = 1
            puts "  To: #{to_date.strftime('%d %B %Y')}"
          end
        when 'category', 'cat'
          unless search_category || i+1 > ARGV.size
            search_category = ARGV[i+1]
            ignore = 1
            puts "Category: '#{search_category}'"
          end
        when 'description', 'desc'
          unless search_description || i+1 > ARGV.size
            search_description = ARGV[i+1]
            ignore = 1
            puts "Description: '#{search_description}'"
          end
        when 'credit', 'income', 'in'
          unless mode
            mode = :credit
            puts "Only incoming transactions"
          end
        when 'debit', 'outgoing', 'out'
          unless mode
            mode = :debit
            puts "Only outgoing transactions"
          end
        when 'above', 'over', 'min'
          unless min_value || i+1 > ARGV.size
            min_value = ARGV[i+1].to_f
            ignore = 1
            puts "Min: #{sprintf('%.2f', min_value)}"
          end
        when 'below', 'under', 'max'
          unless max_value || i+1 > ARGV.size
            max_value = ARGV[i+1].to_f
            ignore = 1
            puts "Max: #{sprintf('%.2f', max_value)}"
          end
        else
          puts "Unknown option '#{arg.downcase}'"
          exit
      end
    else
      ignore -= 1
    end
  end

  if from_date && to_date && to_date < from_date
    puts "Invalid date range"
    exit
  end


  transactions = current_account.search_transactions(from_date, to_date, search_category, search_description, mode, min_value, max_value)
  if report
    breakdown, categories = current_account.monthly_breakdown(transactions)
    debit_cats = categories[:debit].sort
    puts "Date,Balance,IN,OUT,#{debit_cats.join(',')}"
    breakdown.sort_by { |k, v| k }.each do |date, v|
      line = "#{date},#{sprintf('%.2f', v[:last_balance])},#{sprintf('%.2f', v[:total_credit])},#{sprintf('%.2f', v[:total_debit])}"
      debit_cats.each do |cat|
        line << ",#{v[:debit][cat] ? sprintf('%.2f', v[:debit][cat]):0}"
      end
      puts line
    end

  else
    puts BAR_1
    sum_totals = current_account.sum_totals transactions
    category_totals = current_account.category_totals transactions
    print_transactions transactions, sum_totals, category_totals
    puts BAR_1
  end


end


exit

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
