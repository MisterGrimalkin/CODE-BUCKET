require_relative 'utils'
MAX_WIDTH = 30

def print_transactions(transactions, sum_totals, category_totals)

  date_w = 10
  cat_w = 'Category'.size
  desc_w = 'Description'.size
  debit_w = ['Outgoings'.size, curr(sum_totals[:debit]).size].max
  credit_w = ['Income'.size, curr(sum_totals[:credit]).size].max
  balance_w = 'Balance'.size

  transactions.each do |t|
    cat_w = [cat_w, t[:category].size].max
    desc_w = [[desc_w, t[:description].size].max, MAX_WIDTH].min
    balance_w = [balance_w, curr(t[:balance]).size].max
  end

  puts "Date        " +
           "#{'Category'.ljust(cat_w, ' ')}  " +
           "#{'Description'.ljust(desc_w, ' ')}  " +
           "#{'Outgoings'.rjust(debit_w, ' ')}  " +
           "#{'Income'.rjust(credit_w, ' ')}  " +
           "#{'Balance'.rjust(credit_w, ' ')}  "

  puts BAR_2

  transactions.each do |t|
    puts "#{t[:date]}  " +
             "#{t[:category].ljust(cat_w, ' ')}  " +
             "#{t[:description][0..MAX_WIDTH-1].ljust(desc_w, ' ')}  " +
             "#{t[:debit] > 0 ? curr(t[:debit], debit_w) : '-'*debit_w}  " +
             "#{t[:credit] > 0 ? curr(t[:credit], credit_w) : '-'*credit_w}  " +
             "#{t[:balance] > 0 ? curr(t[:balance], balance_w) : '-'*balance_w}  "
  end

  puts BAR_2

  sum_str = "(#{sum_totals[:count]} transactions)"
  cashflow = sum_totals[:credit] - sum_totals[:debit]

  puts "#{sum_str.ljust(16+cat_w+desc_w)}" +
           "#{curr(sum_totals[:debit], debit_w)}  " +
           "#{curr(sum_totals[:credit], credit_w)}  " +
           "(#{(cashflow > 0 ? '+' : '')}#{curr(cashflow)})"

  puts BAR_2

  puts "#{' '*cat_w}  " +
           "#{'Outgoings'.rjust(debit_w, ' ')}  " +
           "#{'Income'.rjust(credit_w, ' ')}  "

  category_totals.each do |cat, totals|
    puts "#{cat.rjust(cat_w, ' ')}  " +
             "#{curr(totals[:debit], debit_w)}  " +
             "#{curr(totals[:credit], credit_w)}  "

  end


end



