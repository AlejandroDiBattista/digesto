require 'mechanize'
require 'pp'
require 'csv'
require 'open-uri'
require 'pdf-reader'
require './base'

login_smt = "http://www.catastrotucuman.gov.ar/novedades/evite-multas-declarando-sus-mejoras/"


class NilClass
  def empty?
    true
  end
end

class TrueClass
  def empty? 
    false
  end
end

class FalseClass
  def empty?
    true
  end
end
OrigenCSV = 'renta.csv'

module Web
  def login_smt
    return $buscar if $agente

    return unless $agent = Mechanize.new
    $agent.get("http://www.catastrotucuman.gov.ar") #novedades/evite-multas-declarando-sus-mejoras/
  
    return false unless $agent.page && $agent.page.forms && form = $agent.page.forms[0]
    form["usuario"]  = 'jmacome'
    form["password"] = 'catastro'
    form["cuenta"]   = '9796'
    form.submit
  
    return unless consulta = $agent.page.links.select{|x| x.href[/form=7/]}.last
    consulta.click

    $buscar = $agent.page.forms.first
  end

  def bajar_smt(padron)
    inicio = Time.new
    salida = {padron: padron}
    # puts padron
    if login_smt()
      $buscar['frmpadron'] = padron
      $buscar.submit

      lista = $agent.page.css("tr td").map{|x| x.text}
      if salida[:existe] = (lista.size == 29)
        salida[:terreno] = lista[17].to_importe
        salida[:mejoras] = lista[19].to_importe
        salida[:ph]      = lista[21].to_importe
        salida[:total]   = lista[25].to_importe
      end
      salida[:bajado] = true
    end
    puts "• Bajado [#{padron}] #{salida[:total]||0 > 0 ?  '😀' : '😢' } #{inicio.info_duracion}"
    salida
  end
  
  def detalle_smt(padron)
    "http://190.3.119.122:85/frmInfoParcelageo.asp?txtpadron=#{padron}"
  end
  
  def boleta(nro)
    reader = PDF::Reader.new(open("http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{nro}"))
    lineas = reader.pages.first.text.split("\n").first(30)
    # p lineas
    { padron: lineas[7].split[2], valuacion: lineas[29].split[2].gsub('$','').to_f }
  end

  
end

include Web
class RegistroSMT < Struct.new(:padron, :bajado, :terreno, :mejoras, :ph, :total, :valuacion )
  
  def self.cargar(datos)
    new.tap{|x| x.cargar(datos)}
  end
  
  def cargar(datos)
    members.each{|campo| self[campo] = datos[campo]}
    normalizar
  end
  
  def normalizar
    self.padron = self.padron.to_s
    self.bajado = !self.bajado.empty?
    [:terreno, :mejoras, :ph, :total].each{|campo| self[campo] = (self[campo]||"").to_importe}
    self.bajado = true if self.total > 0 
    self
  end

  def existe?
    self.total > 0 
  end
end

class RegistroYB < Struct.new(:padron, :bajado, :terreno, :mejoras, :ph, :total, :valuacion )
  
  def self.cargar(datos)
    new.tap{|x| x.cargar(datos)}
  end
  
  def cargar(datos)
    members.each{|campo| self[campo] = datos[campo]}
    normalizar
  end
  
  def normalizar
    self.padron = self.padron.to_s
    self.bajado = !self.bajado.empty?
    [:terreno, :mejoras, :ph, :total].each{|campo| self[campo] = (self[campo]||"").to_importe}
    self.bajado = true if self.total > 0 
    self
  end

  def existe?
    self.total > 0 
  end
end

class BaseDatos
  include Enumerable
  
  @lista = {}
  @origen = ""
  def initialize(origen='renta.csv')
    @lista  = {}
    @origen = origen
  end
  
  def each
    @lista.values.each{|x|yield x}
  end
  
  def agregar(datos)
    @lista ||= {}
    datos = RegistroSMT.cargar(datos) if Hash === datos
    @lista[datos.padron] = datos unless datos.padron.empty?
    # escribir if @lista.count % 10 == 0
  end

  def buscar(*padrones)
    padrones = padrones.flatten.uniq.sort
    padrones = padrones.select{|padron| !traer(padron)}
    
    inicio = Time.new
    Web.login_smt
    puts "▶︎ Buscando... (x#{padrones.size})" if padrones.size > 1
    padrones.each_with_index do |padron, i| 
      agregar( Web.bajar_smt(padron) ) 
      escribir if i % 20 == 19 
    end
    puts "◼︎ #{inicio.info_duracion}" if padrones.size > 1 
  end
  
  def traer(padron)
    @lista[padron.to_s]
  end
  
  def completar
    faltan = select{|dato|!dato.bajado}.map(&:padron)
    buscar(faltan)
  end
  
  def actualizar(forzar=false)
    faltan = select{|dato|forzar || dato.total == 0}.map(&:padron)
    buscar(faltan)
  end
  
  def leer(limpiar=false, origen=nil)
    inicio = Time.new
    origen ||= @origen
    @lista = {} if limpiar
    datos  = CSV.read(origen)
    campos = datos.shift.map(&:to_sym)
    datos.each{|dato| agregar( Hash[ campos.zip(dato) ]) }
    puts "▼ [#{origen}] (x#{datos.count}) #{inicio.info_duracion}"
  end
  
  def escribir(origen=nil)
    inicio = Time.new
    origen ||= @origen
    campos   = first.members
    padrones = @lista.keys.sort_by{|x| "%08i" % x}
    CSV.open(origen, 'w') do |f|
      f << campos
      padrones.each{|padron| f << campos.map{|campo| @lista[padron][campo]} }
    end
    puts "▲ [#{origen}] (x#{count}) #{inicio.info_duracion}"
  end
  
  def actualizar_valuacion(lista)
    lista.each do |padron, valor|
      if a = traer(padron)
        a.valuacion = valor
      end
    end
  end

  def actualizar
    actualizar_valuacion(leer_valuaciones())
    escribir
  end
  
  def self.actualizar
    puts "\nACTUALIZANDO VALUACIONES"
    db = BaseDatos.new
    db.leer
    db.actualizar
    puts 
  end
  
  def self.bajar_vacios
    db = BaseDatos.new
    db.leer
    padrones = db.select{|x|x.total == 0}.map(&:padron)
    db.buscar padrones
    db.escribir
  end
end

def leer_csv(origen)
  inicio = Time.new
  datos  = CSV.read(origen)
  campos = datos.shift.map(&:to_sym)
  puts "▼ [#{origen}] (x #{datos.count}) #{inicio.info_duracion}"
  datos.map{|dato| Hash[ campos.zip(dato) ] }
end

def limpiar_csv(texto)
  (texto||"").gsub('"','')
end

def escribir_csv(datos, destino)
  datos = datos.compact
  campos = datos.map{|x|x.keys}.flatten.uniq
  inicio = Time.new
  CSV.open(destino, 'w') do |f|
    f << campos
    datos.each{|dato| f << campos.map{|campo| limpiar_csv(dato[campo])} }
  end
  puts "▲ [#{destino}] (x #{datos.count}) #{inicio.info_duracion}"
end

def leer_valuaciones()
  datos = leer_csv('boletas.csv')
  salida = {}
  datos.each do |x| 
    padron = x[:padron].to_s
    valor  = x[:valuacion].to_importe
    salida[padron] = valor
  end
  salida
end

def bajar_yb(rango)
  viejos = leer_csv('boletas.csv')
  nuevos = rango.procesar("Bajando Boletas", 100){|nro| boleta(nro)}
  datos  = (nuevos + viejos).uniq
  datos  = datos.select{|x| !x[:padron][/\D/] && x[:valuacion].to_importe > 10000}

  escribir_csv(datos, 'boletas.csv')
  padrones = datos.map{|x| x[:padron] }
end

def limpiar_valuaciones_yb
  puts '-' * 100
  a = leer_csv('boletas.csv')
  puts "Eliminado Padrones incorrectos y valoraciones inferiores a $10.000"
  a = a.select{|x| !x[:padron][/\D/] && x[:valuacion].to_importe > 10000}
  escribir_csv(a, 'boletas.csv' )
  puts
end

# BaseDatos.actualizar

def bajar_todo(grupo=nil)
  vs = leer_valuaciones()
  padrones = vs.keys
  padrones = padrones.select{|x| x.to_i % 4 == grupo} if grupo
  puts "BAJANDO PADRON RENTA #{grupo}"
  db = BaseDatos.new("renta#{grupo}.csv")
  db.leer
  db.buscar padrones
  db.actualizar
end

def juntar_todo
  db = BaseDatos.new("renta0.csv")

  (0..3).each do |i|
    db.leer(false, "renta#{i}.csv")
    puts "#{i} > #{db.count}"
  end

  db.actualizar
  db.escribir("renta.csv")
end


def bajar_boletas(inicial, cantidad=10_000)
  final = cantidad < 100000 ? inicial + cantidad : final = cantidad
  paso = 1000
  (inicial..final).step(paso) do |n|
    puts n
    bajar_yb(n..(n+paso))
  end

  # bajar_todo
  # BaseDatos.actualizar
end

def id(texto)
  texto.strip.downcase.gsub(/[^0-9a-z ]/," ").strip.gsub(/\s+/,'_')
end

def limpiar_domicilio(texto)
  texto = texto.gsub("Piso Dpto",'Dpto')
  texto = texto.gsub("Dpto Block",'Block')
  texto = texto.gsub("Block Mz",'Mz')
  texto = texto.gsub("Mz Casa",'Casa')
  texto = texto.gsub("Casa/Lote -",'-')
end

def catastro(padron)
  url = "http://190.3.119.122:85/frmInfoParcelageo.asp?txtpadron=#{padron}"
  texto = open(url).read.limpiar_espacios
  texto = texto.gsub('SUPERFICIE PROPIA SEGUN PLANO:', 'superficie:')
  texto = texto.gsub('SUPERFICIE SEGUN PLANO:', 'superficie:')

  
  lineas = texto.split('&')
  lineas = lineas.select{|x|x[":"]}.map{|x|x.split(':')}.map{|a,*b| [id(a).to_sym, b.join(' ').limpiar_espacios]}
  lineas = lineas.delete_if{|nombre, valor| nombre[/propietario_legal/]}
  lineas = lineas.delete_if{|nombre, valor| nombre[/sin_hijuela/]}
  
  return nil if lineas.size == 0 
  
  datos = Hash[lineas]
  datos.each{|k,v| datos[k] = datos[k].to_importe if k[/valuacion_/]}
  
  datos[:domicilio]        = limpiar_domicilio(datos[:domicilio])        if datos[:domicilio]
  datos[:domicilio_fiscal] = limpiar_domicilio(datos[:domicilio_fiscal]) if datos[:domicilio_fiscal]
  datos[:superficie]       = datos[:superficie].split.first.to_importe   if datos[:superficie]
  # Hash[]
  datos
end

# bajar_boletas 9267500, 9277500

# pp catastro(4675472)
# puts '-'*100
# exit
def bajar_catastro(nombre='catastro4.csv')
  vs = leer_valuaciones()
  padrones = vs.keys
  puts "Hay #{padrones.size}"
  datos = padrones.procesar("Catastro", 30){|padron| catastro(padron)}
  datos.each{|d|d[:valuacion] = vs[d[:padron]||0]}
  escribir_csv(datos, nombre)
end
