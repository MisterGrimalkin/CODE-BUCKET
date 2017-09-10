require_relative 'utils'

def print_transactions(transactions, sum_totals, category_totals)

  date_w = 10
  cat_w = 'Category'.size
  desc_w = 'Description'.size
  debit_w = 'Outgoings'.size
  credit_w = 'Income'.size
  balance_w = 'Balance'.size

  transactions.each do |t|
    cat_w = [cat_w, t[:category].size].max
    desc_w = [[desc_w, t[:description].size].max, 20].min
    debit_w = [debit_w, sprintf('%.2f', t[:debit]).size].max
    credit_w = [credit_w, sprintf('%.2f', t[:credit]).size].max
    balance_w = [balance_w, sprintf('%.2f', t[:balance]).size].max
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
             "#{t[:description][0..19].ljust(desc_w, ' ')}  " +
             "#{t[:debit] > 0 ? sprintf('%.2f', t[:debit]).rjust(debit_w, ' ') : '-'*debit_w}  " +
             "#{t[:credit] > 0 ? sprintf('%.2f', t[:credit]).rjust(credit_w, ' ') : '-'*credit_w}  " +
             "#{t[:balance] > 0 ? sprintf('%.2f', t[:balance]).rjust(balance_w, ' ') : '-'*balance_w}  "
  end

  puts BAR_2

  sum_str = "(#{sum_totals[:count]} transactions)"
  cashflow = sum_totals[:credit] - sum_totals[:debit]

  puts "#{sum_str.ljust(16+cat_w+desc_w)}" +
           "#{sprintf('%.2f', sum_totals[:debit]).rjust(debit_w, ' ')}  " +
           "#{sprintf('%.2f', sum_totals[:credit]).rjust(credit_w, ' ')}  " +
           "(#{(cashflow > 0 ? '+' : '')}#{sprintf('%.2f', cashflow)})"

  puts BAR_2

  puts "#{' '*cat_w}  " +
           "#{'Outgoings'.rjust(debit_w, ' ')}  " +
           "#{'Income'.rjust(credit_w, ' ')}  "

  category_totals.each do |cat, totals|
    puts "#{cat.rjust(cat_w, ' ')}  " +
             "#{sprintf('%.2f', totals[:debit]).rjust(debit_w, ' ')}  " +
             "#{sprintf('%.2f', totals[:credit]).rjust(credit_w, ' ')}  "

  end


end



