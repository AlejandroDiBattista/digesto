require 'pp'
a = Hash.new{0}
def edad(text, rango)
  (text.to_i/rango).to_i * rango
end
open('clase.txt').each_line{|l| a[edad(2015-l.to_f,10)] += 1 }
a.to_a.reverse.each{|i,n|puts """#{i}-#{i+9}\t#{n} "}
