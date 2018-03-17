require 'csv'
require_relative 'utils'

class Statement

  def initialize(filename, categories={})
    @transactions = []
    hash_csv(filename).each do |row|
      @transactions << {
          date: Date.parse(row["Transaction Date"]),
          description: row["Detail"] ? "#{row["Detail"]} (#{row["Transaction Description"]})" : row["Transaction Description"],
          credit: row["Credit Amount"].to_f,
          debit: row["Debit Amount"].to_f,
          category: row["Category"] || categories[row["Transaction Description"]] || "Misc",
          balance: row["Balance"].to_f
      }
    end

    dates = @transactions.collect { |t| t[:date] }
    @start_date = dates.min
    @end_date = dates.max
    @total_credit = @transactions.inject(0.0) { |sum, t| sum + t[:credit] }.round(2)
    @total_debit = @transactions.inject(0.0) { |sum, t| sum + t[:debit] }.round(2)
    @cashflow = @total_credit - @total_debit
  end

  attr_reader :start_date
  attr_reader :end_date
  attr_reader :total_credit
  attr_reader :total_debit
  attr_reader :cashflow

  def all_transactions
    @transactions
  end

  def transactions(type)
    @transactions.select { |t| t[type] > 0.0 }
  end

  def totals_by_description(type)
    totals = {}
    transactions(type).each do |t|
      description = t[:description]
      totals[description] = 0.0 unless totals[description]
      totals[description] += t[type]
    end
    totals.sort_by { |k, v| v }.reverse
  end

  def totals_by_category(type)
    totals = {}
    transactions(type).each do |t|
      category = t[:category]
      totals[category] = 0.0 unless totals[category]
      totals[category] += t[type]
    end
    totals.sort_by { |k, v| v }.reverse
  end

  def nested_totals(type)
    totals = {}
    transactions(type).each do |t|
      category = t[:category]
      totals[category] = {} unless totals[category]
      description = t[:description]
      totals[category][description] = 0.0 unless totals[category][description]
      totals[category][description] += t[type]
    end
    totals.each do |cat, desc_map|
      totals[cat] = desc_map.sort_by{ | k, v | v }.reverse
    end
    totals.sort_by{ |k, v| k }
  end

  def print_start_date
    puts BAR_1
    header = @start_date.strftime("%B %Y")
    puts "#{header}#{((@cashflow>0 ? '+ ' : '- ')+sprintf('%.2f', @cashflow.abs)).rjust(BAR_WIDTH-6-header.size)}"
    puts
  end

  def print_nested_totals(type, print_transactions=false)
    puts BAR_2
    puts (type==:credit ?
             "INCOME    #{sprintf('%.2f', @total_credit).rjust(BAR_WIDTH-16, ' ')}" :
             "OUTGOINGS #{sprintf('%.2f', @total_debit).rjust(BAR_WIDTH-16, ' ')}" )
    puts
    nested_totals(type).each do |cat, desc_map|
      puts "  #{cat}"
      total = 0.0
      desc_map.each do |desc, amount|
        puts "    #{desc[0..DESCRIPTION_WIDTH].ljust(DESCRIPTION_WIDTH, ' ')}#{sprintf('%.2f', amount).rjust(NUMBER_WIDTH, ' ')}" if print_transactions
        total += amount
      end
      puts "____#{'_'*DESCRIPTION_WIDTH}#{sprintf('%.2f', total).rjust(NUMBER_WIDTH, '_')}______"
    end
    puts
  end



  def monthly_totals(all = false)
    field_width = 29
    # @transactions.each do |transaction|
    #   field_width = [field_width, transaction[:description].size].max
    # end

    puts "-"*50
    puts @start_date.strftime("%B %Y")

    if all
      puts "-"*50
      puts "INCOME:"
      totals_by_category(:credit).each do |k, v|
        puts "   #{k.ljust(field_width, " ")}\t#{sprintf('%.2f', v).rjust(9, " ")}"
      end
    end

    if all
      puts "-"*50
      puts "OUTGOINGS:"
      totals_by_category(:debit).each do |k, v|
        puts "   #{k.ljust(field_width, " ")}\t#{sprintf('%.2f', v).rjust(9, " ")}"
      end
    end

    puts "-"*50
    puts "   " + "INCOME".ljust(field_width, " ") + "\t" + sprintf('%.2f', @total_credit).rjust(9, " ")
    puts "   " + "OUTGOINGS".ljust(field_width, " ") + "\t" + sprintf('%.2f', @total_debit).rjust(9, " ")
    puts "   " + "CASH-FLOW".ljust(field_width, " ") + "\t" + sprintf('%.2f', @cashflow).rjust(9, " ")
    puts "-"*50
    puts
  end

end