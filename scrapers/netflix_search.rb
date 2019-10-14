require 'nokogiri'
require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'

url = URI("https://unogs-unogs-v1.p.rapidapi.com/aaapi.cgi?q=get%3Anew7-!1900%2C2019-!0%2C5-!0%2C10-!0-!Any-!Any-!Any-!gt100-!%7Bdownloadable%7D&t=ns&cl=all&st=adv&ob=Relevance&p=1&sa=and")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

request = Net::HTTP::Get.new(url)
request["x-rapidapi-host"] = 'unogs-unogs-v1.p.rapidapi.com'
request["x-rapidapi-key"] = 'fdfbce96bamsh39e948c681bbfe5p19fea5jsne792f5d0e526'

response = http.request(request)
puts response.read_body