require 'nokogiri'
require 'open-uri'

search_term = ARGV[0] || 'piano'
page_size = 200
url = "https://www.ebay.co.uk/sch/i.html?_from=R40&_nkw=#{search_term}&_in_kw=1&_ex_kw=&_sacat=0&_udlo=&_udhi=&_ftrt=901&_ftrv=1&_sabdlo=&_sabdhi=&_samilow=&_samihi=&LH_LPickup=2&_sadis=15&_stpos=56120&_sargn=-1%26saslc%3D1&_salic=3&_sop=12&_dmd=1&_ipg=50"

doc = Nokogiri::HTML(open(url))

out = File.open("#{ENV['HOME']}/Desktop/results.html", 'w')
out.write("<html>\n<body>\n<table>")
doc.css(".sresult").each do |result|
  collection_only = result.to_s.downcase.include?('collection only')
  if collection_only
    title = result.css("h3").first
    link = result.css("a").first.attr("href")
    img = result.css("img").attr("src").value
    line = "<tr>\n<td><img src='#{img}' width=200/></td>\n<td><a href='#{link}' target='_blank'>#{title.content.strip}</a></td>\n"
    out.write(line)
  end
end
out.write("\n</table>\n</body>\n</html>")
out.close