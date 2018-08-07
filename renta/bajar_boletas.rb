require_relative 'base'
require 'mechanize'
require 'open-uri'
require 'pdf-reader'

class String
  def importe
    gsub('$','').gsub('.','').gsub(',', '.').to_f
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
    boleta = Hash[[:boleta, :anio, :mes, :vencimiento, :monto, :pagada].zip(linea.split)]
    # pp boleta
    boleta[:pagada]= boleta[:pagada]=="Pagada"
    boleta[:mes]   = boleta[:mes].numero
    boleta[:anio]   = boleta[:anio].numero

    boleta[:monto] = monto(boleta[:boleta]) if boleta[:pagada]
    boleta[:monto] = boleta[:monto].importe
    boleta[:padron] = padron
    boleta
  end
end

# boletas(4679294).each{|x|p x }
# puts '-' * 100
# boletas(9333883).each{|x|p x }

def bajar_boletas_completas(grupo=0, bloque = 1000)
  rango = grupo > 0  ? (grupo-1)*bloque...grupo*bloque : 0..-1
  destino = "boletas_completas_#{grupo}.csv"
  unless File.exist?(destino)
    padrones = CSV.leer('boletas.csv').map{|x|x[:padron]}.uniq
    nuevas = padrones[rango].procesar("Bajando Boletas #{rango} -> #{destino}", 100){|padron| boletas(padron)}.flatten
  
    CSV.escribir(nuevas, destino)
  else
    puts "El archivo ya existía > #{grupo}"
  end
end


def leer_boleas_completas
  datos = CSV.leer('boletas_completas.csv')#.first(10)
  datos.each do |x|
    x[:monto]  = x[:monto].to_f
    x[:mes]    = x[:mes].to_i
    x[:anio]   = x[:anio].to_i
    x[:pagado] = x[:pagado] == "true"
  end
  datos
end

def analizar_boletas
  datos = leer_boleas_completas().select{|x|x[:mes] == 99}
  pp datos.first(10)
  puts "Pagado $:   %10.2f" % (a = datos.select{|x|x[:pagado]}.map{|x|x[:monto]}.suma||0)
  puts "Adeudado $: %10.2f" % (b = datos.select{|x|!x[:pagado]}.map{|x|x[:monto]}.suma||0)
  puts "Pagado #:   #{c = datos.select{|x|x[:pagado]}.count}"
  puts "Adeudado #: #{d = datos.select{|x|!x[:pagado]}.count}"
  puts "$  %0.2f%" % (100.0*(a/(a+b)))
  puts "#  %0.2f%" % (100.0*(c/(c+d)))

  puts "$ c/u %7.2f%" % (a/c)
  puts "# c/u %7.2f%" % (b/d)
end

def consolidad_boletas_completas
  datos = Dir['boletas_completas*.csv'].select{|x|x[/\d/]}.map{|origen| CSV.leer(origen)}
  CSV.escribir(datos.flatten.uniq, 'boletas_completas.csv')
end

# (1..26).each{|i|bajar_boletas_completas( i, 1000) }

# consolidad_boletas_completas
b = leer_boleas_completas()
b.select{}
