folder_path = ARGV[0]

if folder_path
	digits = 3
	i = 1
	Dir.glob(folder_path + "/*").sort.each do |f|
		ext = File.extname(f)
		if ['.jpg', '.jpeg', '.png'].include? ext
		    filename = File.basename(f, File.extname(f))
		    new_filename = folder_path + '/' + i.to_s.rjust(digits, '0') + ext
		    File.rename(f, new_filename)
		    i += 1
		end

	end
end
