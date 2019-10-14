def decode_binary(input)
  input.split(' ').collect{ |s| s.to_i(2).chr }.join
end

def encode_binary(input)
  input.scan(/[\w\s,'.!?-]/).collect{ |c| c.ord.to_s(2).rjust(8, '0') }.join(' ')
end

def decode_hex(input)
  spaced_input = ''
  (input.size/2).times {|i| spaced_input << "#{input[i*2..(i*2)+1]} " }
  spaced_input.split(' ').collect{ |s| s.to_i(16).chr }.join
end

def encode_hex(input)
  input.scan(/[\w\s,'.!?-]/).collect{ |c| c.ord.to_s(16).rjust(2, '0') }.join
end

def encode(input, base=16)
  output = ''
  input.each_char do |c|
    output << c.ord.to_s(base).rjust(2, '0') + ' '
  end
  output
end

def decode(input, base=16)
  input.split(' ').collect{ |s| s.to_i(base).chr }.join
end



puts decode_binary '01001000 01100001 01110000 01110000 01111001 00100000 01001110 01100101 01110111 00100000 01011001 01100101 01100001 01110010 00100000 00110010 00110000 00110001 00110111 00100001'

