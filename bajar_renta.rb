require 'mechanize'
require 'pp'
require 'csv'
require 'open-uri'
require 'pdf-reader'
require './base'

login_smt = "http://www.catastrotucuman.gov.ar/novedades/evite-multas-declarando-sus-mejoras/"

class Numeric
  def to_numero
    to_f
  end
end
class String
  def to_numero
    gsub(/[^0-9,.]/,'').gsub(',','.').to_f
  end
end

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
        salida[:terreno] = lista[17].to_numero
        salida[:mejoras] = lista[19].to_numero
        salida[:ph]      = lista[21].to_numero
        salida[:total]   = lista[25].to_numero
      end
      salida[:bajado] = true
    end
    puts " • Bajado [#{padron}] #{salida[:total]||0 > 0 ?  '😀' : '😢' } %0.1fs" % (Time.new - inicio)
    salida
  end
  
  def boleta(nro)
    reader = PDF::Reader.new(open("http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{nro}"))
    lineas = reader.pages.first.text.split("\n").first(30)
    p lineas
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
    [:terreno, :mejoras, :ph, :total].each{|campo| self[campo] = (self[campo]||"").to_numero}
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
    [:terreno, :mejoras, :ph, :total].each{|campo| self[campo] = (self[campo]||"").to_numero}
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
    inicio = Time.new
    puts "▶︎ Buscando... (x#{padrones.size})" if padrones.size > 1
    padrones.each do |padron|
      agregar( Web.bajar_smt(padron)) unless @lista[padron]
    end
    puts "◼︎ %0.1fs" % (Time.new-inicio) if padrones.size > 1 
  end
  
  def traer(padron)
    @lista[padron.to_s]
  end

  def buscar_varios(*padrones)
    padrones = padrones.flatten.uniq.sort
    Web.login_smt
    datos = padrones.procesar("Bajando RENTA"){|padron| Web.bajar_smt(padron)}
    datos.each{|x|agregar(x)}
  end
  
  def completar
    faltan = select{|dato|!dato.bajado}.map(&:padron)
    buscar(faltan)
  end
  
  def actualizar(forzar=false)
    faltan = select{|dato|forzar || dato.total == 0}.map(&:padron)
    buscar(faltan)
  end
  
  def leer(origen=OrigenCSV)
    inicio = Time.new
    @lista = {}
    datos = CSV.read(origen)
    campos = datos.shift.map(&:to_sym)
    datos.each{|dato| agregar( Hash[ campos.zip(dato) ]) }
    puts "◉ Leido   [#{origen}](x#{count}) %0.1fs" % (Time.new-inicio)
  end
  
  def escribir(destino=OrigenCSV)
    inicio = Time.new
    campos = first.members
    padrones = @lista.keys.sort_by{|x| "%08i" % x}
    CSV.open(destino, 'w') do |f|
      f << campos
      padrones.each{|padron| f << campos.map{|campo| @lista[padron][campo]} }
    end
    puts "◉ Escrito [#{destino}](x#{count}) %0.1fs" % (Time.new-inicio)
  end
  
  def actualizar_valuacion(lista)
    lista.each do |padron, valor|
      if a = traer(padron)
        a.valuacion = valor
      end
    end
  end
  
  def self.actualizar
    puts "\nACTUALIZANDO VALUACIONES"
    db = BaseDatos.new
    db.leer
    db.actualizar_valuacion(leer_valuaciones())
    db.escribir
    puts 
  end
end

def leer_csv(origen)
  inicio = Time.new
  datos  = CSV.read(origen)
  campos = datos.shift.map(&:to_sym)
  puts "⦿ Leer     [#{origen}] (x #{datos.count}) %0.1fs" % (Time.new - inicio)
  datos.map{|dato| Hash[ campos.zip(dato) ] }
end

def escribir_csv(datos, destino)
  campos = datos.first.keys
  inicio = Time.new
  CSV.open(destino, 'w') do |f|
    f << campos
    datos.each{|dato| f << campos.map{|campo| dato[campo]} }
  end
  puts "⦿ Escribir [#{destino}] (x #{datos.count}) %0.1fs" % (Time.new - inicio)
end

def leer_valuaciones()
  datos = leer_csv('boletas.csv')
  salida = {}
  datos.each do |x| 
    padron = x[:padron].to_s
    valor  = x[:valuacion].to_numero
    salida[padron] = valor
  end
  salida
end


def bajar_yb(rango)
  viejos = leer_csv('boletas.csv')

  nuevos = rango.procesar("Bajando Boletas", 20){|nro| boleta(nro)}
  datos = (nuevos + viejos).uniq.select{|x|!x[:padron][/\D/]}

  escribir_csv(datos,'boletas.csv')
  padrones = datos.map{|x|x[:padron]}
end

def limpiar_valuaciones_yb
  puts '-' * 100
  a = leer_csv('boletas.csv')
  puts "Eliminado Padrones incorrectos y valoraciones inferiores a $10.000"
  a = a.select{|x| !x[:padron][/\D/] && x[:valuacion].to_numero > 10000}
  escribir_csv(a, 'boletas.csv' )
  puts
end


# BaseDatos.actualizar

vs = leer_valuaciones()
padrones = vs.keys.first(30)

# pp Web.bajar_smt(182790)
db = BaseDatos.new
db.leer
db.buscar padrones
db.escribir

BaseDatos.actualizar
