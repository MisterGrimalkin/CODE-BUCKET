require 'selenium-webdriver'


options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])

@driver = Selenium::WebDriver.for(:chrome, options: options)


def get_movie(url)
  movie = {}

  @driver.get(url)

  @driver.find_elements(css: "h1").each do |h1|
    span = h1.find_element(css: 'span')
    if span
      movie[:year] = span.text.gsub('(','').gsub(')','')
      movie[:title] = h1.text[0..(-2 - span.text.size)]
    end
  end

  @driver.find_elements(css: "a").each do |link|
    href = link.attribute("href")
    if href
      if href.include? "rottentomatoes.com"
        movie[:rt_link] = href
        movie[:rt_rating] = link.attribute("innerHTML").split(">")[-1].strip
      end
      if href.include? "imdb.com"
        movie[:imdb_link] = href
        movie[:imdb_rating] = link.attribute("innerHTML").split(">")[-1].strip
      end
    end
  end

  movie

end

list = File.read('movies.csv').split("\n")

counter = 1

list.each do |movie|
  # puts "Hitting #{movie}"
  puts "#{counter}. #{get_movie(movie)}"
  counter += 1
end

@driver.quit







