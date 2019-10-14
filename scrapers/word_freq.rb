require 'nokogiri'
require 'open-uri'


def word_frequencies(url)
  doc = Nokogiri::HTML(open(url))

  words = Hash.new(0)

  ignore = %w(his her their see hear has which today had seek going general mr mrs miss ms your you source simply from an yes no because therefore said if your on for would that in be by he she could of a to the it and was this who what at we but they have been will with not is as are)

  word_count = 0.0

  doc.css('p').each do |p|
    p.content.gsub(/\.,:;"'/, ' ').split(' ').each do |word|
      unless ignore.include? word.downcase
        words[word.downcase] += 1
        word_count += 1.0
      end
    end
  end

  words.each do |k, v|
    words[k] /= word_count
  end
end


left = word_frequencies("https://www.theguardian.com/politics/2019/sep/02/brexit-no-10-boris-johnson-ignore-legislation-block-no-deal")
right = word_frequencies("https://www.dailymail.co.uk/news/article-7419187/Boris-Johnson-calls-emergency-Cabinet-meeting-TODAY-ahead-crunch-Brexit-vote.html")

common = Hash.new(0)
left.each do |k, v|
  if right[k] > 0
    common[k] += v
  end
end
right.each do |k, v|
  if left[k] > 0
    common[k] += v
  end
end

common.sort_by {|k,v| v}.reverse.first(20).each do |k,v|
  puts "#{k} (#{v})"
end


