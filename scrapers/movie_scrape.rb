require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

url = "https://www.justwatch.com/us/movie/oblivion-2013"


doc = Nokogiri::HTML(open(url))
puts doc
doc.css("h1").each do |h1|
  puts h1
end
# puts doc
# doc.css("div").each do |div|
#   div.css("a").each do |link|
#     puts link.attr("href")
#   end
# end

# out = File.open("#{ENV['HOME']}/Desktop/results.html", 'w')
# out.write("<html>\n<body>\n<table>")
# doc.css(".sresult").each do |result|
#   collection_only = result.to_s.downcase.include?('collection only')
#   if collection_only
#     title = result.css("h3").first
#     link = result.css("a").first.attr("href")
#     img = result.css("img").attr("src").value
#     line = "<tr>\n<td><img src='#{img}' width=200/></td>\n<td><a href='#{link}' target='_blank'>#{title.content.strip}</a></td>\n"
#     out.write(line)
#   end
# end
# out.write("\n</table>\n</body>\n</html>")
# out.close


