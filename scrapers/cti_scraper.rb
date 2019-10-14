require 'nokogiri'
require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'
require 'openssl'

# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

ROOT = 'https://www.ctidirectory.com/'

@file = File.open('output.csv', 'w')
@i = 1

def iterate_headings
  puts "Starting"
  @file.write("Company Name,Category,Subcategory,Address,Telephone,Email,Website,Products\n")
  doc = Nokogiri::HTML(open(URI(ROOT)))
  items = doc.css('.td_tab_index')
  puts "Processing #{items.size} headings"
  items.each do |item|
    if (link = item.css('a').first)
      puts "#{item.text.strip}"
      iterate_sub_headings(item.text.strip, link.attr('href'))
    end
  end
end

def iterate_sub_headings(heading, url)
  doc = Nokogiri::HTML(open(URI(ROOT+url)))
  items = doc.css('.alinks3')
  items.each do |item|
    puts "\t#{item.text.strip}"
    iterate_companies(heading, item.text.strip, item.attr('href'))
  end

end

def iterate_companies(heading, subheading, url)
  doc = Nokogiri::HTML(open(URI(ROOT+url)))
  links = doc.css('a')
  links.each do |link|
    if link.attr('href').include? '/company.cfm'
      puts "\t\t#{@i}. #{link.text.strip}"
      @i += 1
      data = get_company_info(link.attr('href'))
      data[:name] = link.text.strip
      data[:cat] = heading
      data[:subcat] = subheading
      @file.write("#{csv_row(data).join(',')}\n")
    end
  end
end

def find_email_address(url)
  result = ''
  if url
    begin
      doc = Nokogiri::HTML(open(URI(url)))
      if doc.to_s.include?('@')
        emails = []
        doc.to_s.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i).each do |email|
          emails << email unless emails.include? email
        end
        if emails.size > 1
          host = url.split('.')[1]
          email_to_use = nil
          emails.each do |email|
            if email.include? host
              email_to_use = email
            end
          end
          if email_to_use
            emails = [email_to_use]
          end
        end
        result = emails.join(',')
      end
    rescue
# ignored
    end
  end
  result
end


def csv_row(data)
  result = [quote(data[:name]), quote(data[:cat]), quote(data[:subcat])]
  result << quote("#{data[:streetAddress]}, #{data[:addressLocality]}, #{data[:addressRegion]}, #{data[:postalCode]}")
  result << quote(data[:telephone])
  result << quote(find_email_address(data[:website]))
  result << quote(data[:website])
  result << "TBD"
  result
end

def quote(str)
  "\"#{str}\""
end

def get_company_info(url)
  doc = Nokogiri::HTML(open(URI("https://www.ctidirectory.com#{url}")))
  data = {}
  doc.css('span').each do |span|
    if (prop = span.attr('itemprop'))
      data[prop.to_sym] = span.text
    end
    if span.text.include? 'Toll Free'
      data[:telephone] = span.next_element.text
    end
    if span.text.include? 'Website'
      data[:website] = span.next_element.css('a').first.attr('href')
    end
  end
  data
end

iterate_headings
