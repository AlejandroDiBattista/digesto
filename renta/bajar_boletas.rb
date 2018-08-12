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
      boleta[:pagada] = boleta[:pagada]=="Pagada"
      boleta[:mes]    = boleta[:mes].numero
      boleta[:anio]   = boleta[:anio].numero
      if boleta[:pagada]
        boleta[:monto]  = bajar_monto(boleta[:boleta]).importe('.')
      else
        boleta[:monto] = boleta[:monto].importe(',')
      end
      boleta[:padron] = padron
      boleta
    end
  end
end

include Web

class Boleta < Struct.new(:boleta, :anio, :mes, :vencimiento, :monto, :pagada, :padron)
  def normalizar
    self.anio   = self.anio.to_i if String === self.anio
    self.mes    = self.mes.to_i  if String === self.mes
    self.pagada = self.pagada == 'pagada' || self.pagada == 'true'
    self.monto  = self.monto.importe('.') if String === self.monto
    self.vencimiento = self.vencimiento.fecha
  end
end

class Catastro < Struct.new(:padron, :nomenclatura, :categoria, :mat_ord, :alta, :caracter, :domicilio, :responsable_fiscal, :domicilio_fiscal, :codigo_valuacion, :rige_valuacion, :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total, :inscripcion_dominial, :plano_nro, :verificacion_nro, :superficie, :valuacion)  
  attr_accessor :boletas
  
  def normalizar
    [:valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total, :superficie, :valuacion].each do |campo|
      self[campo] = self[campo].to_importe
    end
    
    self.responsable_fiscal = self.responsable_fiscal.simplificar
    self.padron             = self.padron.to_s
  end
    
  def agregar(boleta)
    self.boletas ||= []
    self.boletas.delete_if{|x|x.anio == boleta.anio && x.mes == boleta.mes}
    self.boletas << boleta
  end
  
  def limpiar_deuda
    self.boletas ||= []
    self.boletas = boletas.group_by{|x|x.anio}.map do |_, items|
      dm, da = *items.group_by{|x|x.mes == 99}
      (da.first && da.first.pagada) ? da : dm
    end.flatten
  end
  
  def deuda
    limpiar_deuda.suma(&:monto)
  end
  
  def pagado
    limpiar_deuda.select(&:pagada).suma(&:monto)
  end
  
  def morosidad
    (deuda - pagado) / deuda
  end
end

class Boletas < Almacen
  def initialize
    super(Boleta)
  end
  
  def self.leer(nombre=nil)
    new.leer(nombre)
  end

  def padrones
    map(&:padron).uniq
  end
  
  def bajar(padron)
    Web.bajar_boletas(padron).each{|b|agregar(b)}
  end
end

class Catastros < Almacen
  def initialize
    super(Catastro)
  end
  
  def self.leer(nombre=nil)
    new.leer(nombre)
  end
  
  def padrones
    map(&:padron).uniq
  end

  def bajar_boletas(cantidad=500)
    b = Boletas.leer
    padrones = (self.padrones - b.padrones).shuffle
    while !(nuevos = padrones.shift(cantidad)).empty?
      puts "Hay #{padrones.size} pendientes"
      nuevos.procesar("Bajando", 50){|padron| b.bajar(padron)}
      b.escribir
    end
    self
  end
end

def analizar_boletas
  datos = Boletas.leer

  tmp = datos.filtrar{|x|x.padron == '877030'}
  p tmp.count
  montos = tmp.map{|x|[x.monto, x.padron, x.boleta]}.sort.reverse
  pp montos.first(20)
  pp datos.first(3)
  
  puts "Pagado $:   %10.2f" % (a = datos.select{|x| x.pagada}.map{|x|x.monto}.suma||0)
  puts "Adeudado $: %10.2f" % (b = datos.select{|x|!x.pagada}.map{|x|x.monto}.suma||0)
  puts "Pagado #:   #{c = datos.select{|x|x.pagada}.count}"
  puts "Adeudado #: #{d = datos.select{|x|!x.pagada}.count}"
  
  puts "$  %0.2f%" % (100.0*(a/(a+b)))
  puts "#  %0.2f%" % (100.0*(c/(c+d)))

  puts "$ c/u %7.2f%" % (a/c)
  puts "# c/u %7.2f%" % (b/d)
end

# analizar_boletas
def generar_deuda
  b = Boletas.leer
  c = Catastros.leer
  b.each do |x|
    if i = c.traer(x.padron)
      i.agregar(x)
    else
      puts "ERROR #{x.padron} no existe"
    end
  end
  CSV.escribir(c, 'deudas')
end

def analizar_calidad_datos
  b = Boletas.leer
  p "Años: #{b.map(&:anio).uniq}"
  p "Mes : #{b.map(&:mes).uniq.sort}"
  p "Pagados #{b.map(&:pagada).contar}"

  a17 = b.filtrar{|x|x.mes == 99 && x.anio == 2017}
  a18 = b.filtrar{|x|x.mes == 99 && x.anio == 2018}

  puts "Hay #{a17.count} planes anuales en #{2017}"
  puts "Hay #{a18.count} planes anuales en #{2018}"

  e = a18.map{|x|[x.padron, x.monto.to_i, x.pagada]}
  f = a18.map{|x|[x.padron, x.monto.to_i]}

  puts "#{e.uniq.size}"
  puts "#{f.uniq.size}"
  puts "#{a18.map(&:pagada).contar}"

  puts a18.select(&:pagada).first(10)
end



# Catastros.leer.bajar_boletas
generar_deuda