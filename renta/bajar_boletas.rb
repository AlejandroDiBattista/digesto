require_relative 'base'

module Web
  require 'mechanize'
  require 'open-uri'
  require 'pdf-reader'

  def bajar_monto(boleta)
    url = "http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{boleta}"
    reader = PDF::Reader.new(open(url))
    linea = reader.pages.first.text.split("\n")[9].split
    linea[-2]
  end

  $agente = Mechanize.new
  
  def bajar_boletas(padron)
    $agente.post('http://boletas.yerbabuena.gob.ar/busqueda.php', "padron" => padron)
    $agente.page.css("table tr").map(&:text)[1..-1].map do |linea|
      boleta = Hash[[:boleta, :anio, :mes, :vencimiento, :monto, :pagada].zip(linea.split)]
      # pp boleta
      boleta[:pagada] = boleta[:pagada]=="Pagada"
      boleta[:mes]    = boleta[:mes].numero
      boleta[:anio]   = boleta[:anio].numero

      boleta[:monto]  = bajar_monto(boleta[:boleta]) if boleta[:pagada]
      boleta[:monto]  = boleta[:monto].importe
      boleta[:padron] = padron
      boleta
    end
  end
end

include Web

def bajar_boletas_completas(grupo=0, bloque = 1000)
  rango = grupo > 0  ? (grupo-1)*bloque...grupo*bloque : 0..-1
  destino = "boletas_completas_#{grupo}.csv"
  unless File.exist?(destino)
    padrones = CSV.leer('boletas.csv').map{|x|x[:padron]}.uniq
    nuevas = padrones[rango].procesar("Bajando Boletas #{rango} -> #{destino}", 100){|padron| bajar_boletas(padron)}.flatten
  
    CSV.escribir(nuevas, destino)
  else
    puts "El archivo ya existía > #{grupo}"
  end
end

def consolidad_boletas_completas
  datos = Dir['boletas_completas*.csv'].select{|x|x[/\d/]}.map{|origen| CSV.leer(origen)}
  CSV.escribir(datos.flatten.uniq, 'boletas_completas.csv')
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


class Boleta < Struct.new(:boleta, :anio, :mes, :vencimiento, :monto, :pagada, :padron)
  def normalizar
    self.anio   = self.anio.to_i
    self.mes    = self.mes.to_i
    self.pagada = self.pagada == 'pagada'
    self.monto  = self.monto.importe
  end
end

boletas = Almacen.new(Boleta).leer
puts "BOLETAS #{boletas.count}"
puts boletas.first(5)


class Catastro < Struct.new(:padron, :nomenclatura, :categoria, :mat_ord, :alta, :caracter, :domicilio, :responsable_fiscal, :domicilio_fiscal, :codigo_valuacion, :rige_valuacion, :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total, :inscripcion_dominial, :plano_nro, :verificacion_nro, :superficie, :valuacion)  
  def normalizar
    [:valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total,:superficie, :valuacion].each do |campo|
      self[campo] = self[campo].to_importe
    end
    
    self.responsable_fiscal = self.responsable_fiscal.simplificar
    self.padron             = self.padron.to_s
  end
end

catastros = Almacen.new(Catastro).leer
puts "CATASTROS #{catastros.count}"
puts catastros.first(5)
