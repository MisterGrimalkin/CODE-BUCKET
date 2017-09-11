DESCRIPTION_WIDTH = 30
NUMBER_WIDTH = 10
BAR_WIDTH = 100
BAR_1 = "="*BAR_WIDTH
BAR_2 = "-"*BAR_WIDTH
BAR_3 = "_"*BAR_WIDTH

def hash_csv(filename)
  data = []
  headings = nil
  CSV.parse(File.read(filename).gsub("'", '')) do |row|
    if headings
      row_data = {}
      row.each_with_index do |value, index|
        row_data[headings[index]] = value
      end
      data << row_data
    else
      headings = row
    end
  end
  data
end

def match_any?(inspect_value, search_terms, exact = false, match_case = false)
  value = match_case ? inspect_value : inspect_value.downcase
  search_terms.each do |search_term|
    term = match_case ? search_term : search_term.downcase
    return true if value == term || (!exact && value.include?(term))
  end
  false
end

def curr(value, column_width = nil)
  str = sprintf('%.2f', value || 0)
  column_width ? str.rjust(column_width, ' ') : str
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

