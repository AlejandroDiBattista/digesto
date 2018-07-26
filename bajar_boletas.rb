require './base'
require 'mechanize'
require 'open-uri'
require 'pdf-reader'

class String
  def importe
    gsub('$','').to_f
  end
  def numero
    gsub(/\D/,'').to_i
  end
end
  
def boleta(nro, verboso=false)
  url = "http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{nro}"
  puts(url) if verboso

  reader = PDF::Reader.new(open(url))
  lineas = reader.pages.first.text.split("\n").first(30)
  if verboso
    lineas.each_with_index do |linea, i|
      print " %3i) " % (i)
      puts "[#{linea}] > #{linea.split}"
    end
  end
  lineas = lineas.map{|x|x.split}
  datos  = { padron: lineas[7][2], valuacion: lineas[29][2].importe, boleta: nro, 
             importe: lineas[9][-2].importe, mes: lineas[7][-3].numero, año: lineas[7][-1].numero }
  pp(datos) if verboso

  datos
end

def monto(boleta)
  url = "http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{boleta}"
  reader = PDF::Reader.new(open(url))
  linea = reader.pages.first.text.split("\n")[9].split
  linea[-2]
end

$agente = Mechanize.new

def boletas(padron)
  $agente.post('http://boletas.yerbabuena.gob.ar/busqueda.php', "padron" => padron)
  $agente.page.css("table tr").map(&:text)[1..-1].map do |linea|
    boleta = Hash[[:boleta, :año, :mes, :vencimiento, :monto, :pagada].zip(linea.split)]

    boleta[:pagada]= boleta[:pagada]=="Pagada"
    boleta[:mes]   = boleta[:mes].numero
    boleta[:año]   = boleta[:año].numero

    boleta[:monto] = monto(boleta[:boleta]) if boleta[:pagada]
    boleta[:monto] = boleta[:monto].importe
    boleta[:padron] = padron
    boleta
  end
end


# boletas(4679294).each{|x|p x }
# puts '-' * 100
# boletas(4679296).each{|x|p x }

def bajar_boletas_completas
  padrones = CSV.leer('boletas.csv').map{|x|x[:padron]}.uniq
  b = padrones.procesar("Bajando Boletas",100){|padron| boletas(padron)}.flatten
  CSV.escribir(b, 'boletas_completas.csv')
end

def leer_boleas_completas
  datos = CSV.leer('boletas_completas.csv')#.first(10)
  datos.each do |x|
    x[:monto] = x[:monto].to_f
    x[:mes] = x[:mes].to_f
    x[:año] = x[:año].to_f
    x[:pagado] = (x[:pagado] == "true")
  end
  datos
end

datos = leer_boleas_completas().select{|x|x[:mes] == 99}

puts "Pagado $:   %10.2f" % (a = datos.select{|x|x[:pagado]}.map{|x|x[:monto]}.suma||0)
puts "Adeudado $: %10.2f" % (b = datos.select{|x|!x[:pagado]}.map{|x|x[:monto]}.suma||0)
puts "Pagado #:   #{c = datos.select{|x|x[:pagado]}.count}"
puts "Adeudado #: #{d = datos.select{|x|!x[:pagado]}.count}"
puts "$  %0.2f%" % (100.0*(a/(a+b)))
puts "#  %0.2f%" % (100.0*(c/(c+d)))

puts "$ c/u %7.2f%" % (a/c)
puts "# c/u %7.2f%" % (b/d)
