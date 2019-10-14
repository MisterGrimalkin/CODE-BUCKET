require 'selenium-webdriver'

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless', 'whitelisted-ips=""'])

driver = Selenium::WebDriver.for(:chrome, options: options)

driver.get('https://www.justwatch.com/us/movies')

counter = 1
urls = []
file = File.open("movies.csv", 'w')

def add_movie(url)
end

puts driver.title

body = driver.find_element(css: 'body')


driver.find_elements(css: 'h1').each do |h1|
  begin
  h1.click
  rescue => e
    puts e.message
  end
end


# start = Time.now

while true
  puts "Scanning...."
  driver.find_elements(css: 'a').each do |link|
    url = link.attribute('href')
    if url && url.include?('/us/movie/')
      unless urls.include? url
        puts "#{counter}. #{url}"
        urls << url
        file.write("#{url}\n")
        counter += 1
      end
      body.send_keys(:page_down)
    end
  end
  10.times {|i| body.send_keys(:page_up) }
  # elapsed = Time.now - start
  # time_per_movie = elapsed / counter
  # time_remaining = (75000 - counter) * time_per_movie
  # puts "#{time_per_movie}sec/movie. Remaining: #{time_remaining} seconds"
end

driver.quit