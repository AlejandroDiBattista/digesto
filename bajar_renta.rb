require 'mechanize'
require 'pp'
require 'csv'

Login = "http://www.catastrotucuman.gov.ar/novedades/evite-multas-declarando-sus-mejoras/"

class Numeric
  def to_numero
    to_f
  end
end
class String
  def to_numero
    gsub(/[^0-9,]/,'').gsub(',','.').to_f
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
OrigenCSV = './renta.csv'

module Web
  def login
    return $buscar if $agente

    return unless $agent = Mechanize.new
    $agent.get("http://www.catastrotucuman.gov.ar") #novedades/evite-multas-declarando-sus-mejoras/
  
    return false unless form = $agent.page.forms[0]
    form["usuario"]  = 'jmacome'
    form["password"] = 'catastro'
    form["cuenta"]   = '9796'
    form.submit
  
    return unless consulta = $agent.page.links.select{|x| x.href[/form=7/]}.last
    consulta.click

    $buscar = $agent.page.forms.first
  end

  def bajar(padron)
    inicio = Time.new
    salida = {padron: padron}
    if login()
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
end

include Web
class Registro < Struct.new(:padron, :bajado, :terreno, :mejoras, :ph, :total )
  
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
    datos = Registro.cargar(datos) if Hash === datos
    @lista[datos.padron] = datos unless datos.padron.empty?
  end
  
  def buscar(*padrones)
    padrones = padrones.flatten.uniq.sort
    inicio = Time.new
    puts "▶︎ Buscando... (x#{padrones.size})" if padrones.size > 1
    padrones.each do |padron|
      agregar( Web.bajar(padron)) unless @lista[padron]
    end
    puts "◼︎ %0.1fs" % (Time.new-inicio) if padrones.size > 1 
  end
  
  def leer(origen=OrigenCSV)
    inicio = Time.new
    @lista = {}
    datos = CSV.read(origen)
    campos = datos.shift.map(&:to_sym)
    datos.each{|dato| agregar( Hash[ campos.zip(dato) ]) }
    puts "◉ Leido (x#{count}) %0.1fs" % (Time.new-inicio)
  end
  
  def completar
    faltan = select{|dato|!dato.bajado}.map(&:padron)
    buscar(faltan)
  end
  
  def actualizar(forzar=false)
    faltan = select{|dato|forzar || dato.total == 0}.map(&:padron)
    buscar(faltan)
  end
  
  def escribir(destino=OrigenCSV)
    inicio = Time.new
    campos = first.members
    padrones = @lista.keys.sort_by{|x| "%08i" % x}
    CSV.open(destino, 'w') do |f|
      f << campos
      padrones.each{|padron| f << campos.map{|campo| @lista[padron][campo]} }
    end
    puts "◉ Escrito (x#{count}) %0.1fs" % (Time.new-inicio)
  end
end

db = BaseDatos.new
db.leer
db.actualizar
db.buscar((180_068..180_080).to_a)

db.escribir