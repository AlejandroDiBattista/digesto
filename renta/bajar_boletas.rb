require_relative 'base'

module Web
  require 'mechanize'
  require 'open-uri'
  require 'pdf-reader'

  def bajar_monto(boleta)
    url = "https://boletas.yerbabuena.gob.ar//imprimir.php?id=#{boleta}"
    reader = PDF::Reader.new(open(url))
    lineas = reader.pages.first.text.split("\n")
    linea = lineas[9].split
    linea[-2]
  end

  def bajar_datos(boleta)
    url = "https://boletas.yerbabuena.gob.ar//imprimir.php?id=#{boleta}"
    reader = PDF::Reader.new(open(url))
    lineas = reader.pages.first.text.split("\n")||[]
    # p url
    # lineas.each_with_index{|l,i| puts "#{i}) >> #{l}"}
    {
      contribuyente: (lineas[4][50..-1]||"").strip, 
      titular:       (lineas[13]||"").strip,
      domicilio:     (lineas[15]||"").strip
    }
  end

  $agente = Mechanize.new
  
  def bajar_boletas(padron)
    $agente.post('https://boletas.yerbabuena.gob.ar/busqueda.php', "padron" => padron)
    $agente.page.css("table tbody tr").map(&:text)[0..-1].map do |linea|
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
  
  def bajar_catastro(padron, verboso=false)
    url = "http://190.3.119.122:85/frmInfoParcelageo.asp?txtpadron=#{padron}"
    puts(url) if verboso

    texto = open(url).read.limpiar_espacios
  
    texto = texto.gsub('SUPERFICIE PROPIA SEGUN PLANO:', 'superficie:')
    texto = texto.gsub('SUPERFICIE SEGUN PLANO:', 'superficie:')
  
    lineas = texto.split('&')
    pp(lineas) if verboso
  
    lineas = lineas.select{|x|x[":"]}.map{|x|x.split(':')}.map{|a, *b| [a.to_id, b.join(' ').limpiar_espacios]}
    lineas = lineas.delete_if{|nombre, valor| nombre[/propietario_legal/]}
    lineas = lineas.delete_if{|nombre, valor| nombre[/hijuela/]}
  
    return nil if lineas.size == 0 
  
    datos = Hash[lineas]
    datos.each{|k, v| datos[k] = datos[k].to_importe if k[/valuacion_/]}
    datos[:id] = padron
    datos[:alta]             = datos[:alta].limpiar_fecha
    datos[:domicilio]        = datos[:domicilio].limpiar_domicilio         if datos[:domicilio]
    datos[:domicilio_fiscal] = datos[:domicilio_fiscal].limpiar_domicilio  if datos[:domicilio_fiscal]
    datos[:superficie]       = datos[:superficie].split.first.to_importe   if datos[:superficie]

    datos
  end
  
end

include Web

class Boleta < Struct.new(:boleta, :anio, :mes, :vencimiento, :monto, :pagada, :padron)
  def normalizar
    self.anio   = self.anio.to_i if String === self.anio
    self.mes    = self.mes.to_i  if String === self.mes
    self.pagada = self.pagada.boolean
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
    
    self.responsable_fiscal = (self.responsable_fiscal||"").simplificar
    self.padron             = self.padron.to_s
  end
    
  def agregar(boleta)
    return unless boleta
    self.boletas ||= []
    self.boletas.delete_if{|x|x.anio == boleta.anio && x.mes == boleta.mes}
    self.boletas << boleta
  end
  
  def limpiar_deuda
    self.boletas ||= []

    self.boletas = boletas.group_by{|x|x.anio}.map do |_, items|
      dm, da = *items.group_by{|x|x.mes == 99}.map(&:last)
      (da && da.first && da.first.pagada) ? da : dm
    end.flatten
    
    self.boletas
  end
  
  def deuda(anio=nil)
    tmp = limpiar_deuda
    tmp = tmp.select{|x|x.anio == anio} if anio
    tmp.suma(&:monto)
  end
  
  def pagado(anio=nil)    
    tmp = limpiar_deuda
    tmp = tmp.select{|x|x.anio == anio} if anio
    tmp.select(&:pagada).suma(&:monto)
  end
  
  def morosidad(anio=nil)
    1.0 - pagado(anio) / deuda(anio)
  end
  
  def bajar(padron)
    
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

  def bajar_boletas(padrones=nil, cantidad=500)
    b = Boletas.leer
    padrones ||= b.padrones
    padrones = (padrones - self.padrones).shuffle
    puts "Debo bajar #{padrones.size} (#{self.padrones.size})"
    while !(nuevos = padrones.shift(cantidad)).empty?
      puts "Hay #{padrones.size} pendientes"
      nuevos.procesar("Bajando", 50){|padron| b.bajar(padron)}
      b.escribir
    end
    self
  end
  
  def cargar(boletas)
    boletas.each do |x|
      if i = traer(x.padron)
        i.agregar(x)
      else
        puts "ERROR #{x.padron} no existe"
      end
    end
  end
  
  def bajar(padron, cantidad=500)
    if Array === padron
      padrones = (padron - self.padrones).shuffle
      puts "Debo bajar #{padrones.size} (Hay #{self.padrones.size})"
      while !(nuevos = padrones.shift(cantidad)).empty?
        puts "Hay #{padrones.size} pendientes"
        nuevos.procesar("Bajando", 50){|padron| self.bajar(padron)}
      end
    else
      agregar(Web.bajar_catastro(padron))
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
  c = Catastros.leer
  c.cargar(Boletas.leer)
  d = c.map do |x|
    {
      padron: x.padron, 
      deuda:      x.deuda.to_i,       pagado:      x.pagado.to_i, 
      deuda_2017: x.deuda(2017).to_i, pagado_2017: x.pagado(2017).to_i, 
      deuda_2018: x.deuda(2018).to_i, pagado_2018: x.pagado(2018).to_i, 
      superficie: x.superficie.to_i,  valuacion_yb: x.valuacion.to_i, valucion_tuc: x.valuacion_total.to_i, 
      titular:    x.responsable_fiscal.limpiar_nombre, 
      domicilio:  x.domicilio.limpiar_domicilio
    }
  end
  CSV.escribir(d, 'deuda_completa')
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
# generar_deuda
# c = Catastros.leer
# c.cargar(b=Boletas.leer)
# a = c.traer('875285')
# pp a
# pp a.boletas
#
# pp b.traer('93482076')
# pp bajar_boletas('875285')

# b = Boletas.leer
# pp b.select{|x|x.padron == '875285'}

# a = CSV.leer('renta/boleta.csv')
# pp a.select{|x|x[:padron] == '875285'}
# puts '-' * 100
# pp bajar_boletas('875285')

# Catastros.leer.bajar_boletas
# generar_deuda

# pp Web.bajar_datos(9617728)
# exit

a = CSV.leer('padrones_yb.csv')
b = a.map{|x|x[:padron]} 

c = Catastros.new
c.bajar(b)
c.escribir
exit

b = Boletas.leer

aux = b.padrones.first(100)
p aux

titulares = aux.procesar("Bajando Boletas") do |padron|
  bs = Web.bajar_boletas(padron)
  if bs && bs.first
    p [padron, bs.size, bs.first]
    aux = Web.bajar_datos(bs.first[:boleta])
    aux[:padron] = padron
    aux
  else
    nil
  end
end.compact

pp titulares
CSV.escribir(titulares, :titulares)

