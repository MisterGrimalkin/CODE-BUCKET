def is_prime(n)
  if n > 1
    ((n/2)+1).times do |i|
      if (i+1)>1 && n % (i+1) == 0
        return false
      end
    end
  else
    return false
  end
  return true
end

c = 1
1000.times do |i|
  if is_prime(i)
    puts "#{c}. #{i}"
    c += 1
  end
end