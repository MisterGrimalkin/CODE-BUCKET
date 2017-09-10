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