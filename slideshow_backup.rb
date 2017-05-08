require 'fileutils'

TEST = false

SEQ_I = "img-seq"
SEQ_G = "gif-seq"

def first(dir, count)
  [dir, count, 0, 0.5]
end

def mid(dir, count)
  [dir, count, 0.25, 0.75]
end

def last(dir, count)
  [dir, count, 0.5, 1]
end

def all(dir, count)
  [dir, count]
end

MODES = {

}

FUNCTIONS = {
    all: "all_img(value) + all_gif(value)",
    img: "all_img(value)",
    gif: "all_gif(value)",
    seq: "random_seq(value)"
}

def all_img(count)
  []
end

def all_gif(count)
  []
end

def random_seq(number)
  folders = Dir.glob(SEQ_I+"/*").shuffle.first(5).sort
  folders += Dir.glob(SEQ_G+"/*").shuffle.first(2).sort
  result = []
  folders.each do |f|
    result << [f, number]
  end
  result
end

class SlideShowBuilder

  def build(mode)
    @directory = "slideshow-#{Time.now.to_i}"
    @used = File.exist?("used.dat") ? File.read("used.dat").split("\n") : []
    @counter = 0
    if mode.include?(":")
      key = mode.split(":")[0].to_sym
      value = mode.split(":")[1].to_i
      folders = eval(FUNCTIONS[key])
    else
      folders = MODES[mode.to_sym]
    end
    if folders
      Dir.mkdir(@directory) unless TEST
      add_to_slideshow("00.gif")
      folders.each do |dir, count, min, max|
        sieve_directory(dir, count, min, max)
      end
      puts "#{@counter} files"
      system "eog -f #{@directory} 2> /dev/null" unless TEST
      FileUtils.rm_rf(@directory) unless TEST
      File.write("used.dat", @used.join("\n"))
    end
  end

  def sieve_directory(dirname, number, min=0.0, max=1.0)
    all_files = Dir.glob(dirname+"/*")
    files = all_files.reject { |f| @used.include? f }.sort
    if files.length < number
      @used.reject!{|u| u.include? dirname}
      files = all_files.sort
    end
    min = ((min || 0.0) * files.size).to_i
    max = ((max || 1.0)* files.size).to_i
    files = files[min..max]
    files.shuffle.first(number).sort.each do |f|
      add_to_slideshow(f)
      @used << f
    end
  end

  def add_to_slideshow(filename)
    output_filename = "#{@directory}/#{@counter.to_s.rjust(4, "0")}.#{filename.split(".")[-1]}"
    FileUtils.cp(filename, output_filename) unless TEST
    puts filename if TEST
    @counter += 1
  end

end

if ARGV[0]
  SlideShowBuilder.new.build(ARGV[0])
else
  puts "SLIDESHOWS:"
  counts = {}
  folder_counts = {}
  maxlength = 0
  MODES.each do |k, folders|
    count = 0
    used_folders = []
    maxlength = [maxlength, k.length].max
    folders.each do |f|
      count += f[1]
      used_folders << f unless used_folders.include? f
    end
    counts[k] = count
    folder_counts[k] = used_folders.size
  end
  MODES.each_key do |k|
    puts " #{k.to_s.ljust(maxlength, ' ')}  #{counts[k]} (#{folder_counts[k]})"
  end
  FUNCTIONS.each_key do |k|
    puts " #{k}:N"
  end
end
