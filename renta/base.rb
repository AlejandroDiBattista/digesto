require 'pp'
require 'csv'

class Numeric
  def hora
    "%02i:%02i:%02i" % [(self / 60 / 60) % 60, (self / 60) % 60, self % 60]
  end
end

class Object
  def to_importe
    to_s.to_importe
  end
end

class String
  
  def importe
    gsub('$', '').gsub('.', '').gsub(',', '.').to_f
  end

  def numero
    gsub(/\D/, '').to_i
  end
  
  def limpiar_espacios
    gsub(/\s+/, ' ').strip
  end
  
  def to_importe
    self.gsub(',', '.').gsub(/[^0-9.]/, '').to_f
  end

  def to_id
    gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
  end
  
  def limpiar_csv
    gsub(';','').gsub('"','').gsub(' ',' ')
  end
    
  def simplificar
    gsub('Á','a').gsub('É','e').gsub('Í','i').gsub('Ó','o').gsub('Ú','u').
    gsub('á','a').gsub('é','e').gsub('í','i').gsub('ó','o').gsub('ú','u').
    gsub(/\s+/,' ').strip.downcase.
    gsub(/[^a-zñ0-9 .()-]/i, '')
  end

end

class Time
  def duracion
    Time.new - self
  end

  def falta(porcentaje)
    [0, duracion / porcentaje - duracion].max
  end
  
  def to_fecha
    self.to_s.split[0]
  end
  
  def info_duracion
    d = duracion
    m = (d / 60).to_i
    h = (m / 60).to_i
    if m == 0 
      "⧗ %0.1fs" % d
    else
      "⧗ #{h}h #{m % 60}m #{d.to_i % 60}"
    end.gsub("0h","").gsub("0m","").strip
  end
end

class Numeric
  def empty?
    self == 0
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

class Hash
  def normalizar
    keys.select{|x|String === x}.each do |x|
      self[x.to_sym] = self[x]
      delete(x)
    end
    self
  end
  
  def filtrar(*campos)
    (keys - campos.flatten).each{|campo| delete campo}
    self
  end
end

module Kernel
  require 'thread'
  
  alias :_puts :puts
  
  $nivel  = []
  $sincro = Mutex.new

  def sincro
    $sincro.synchronize{ yield }
  end
    
  def puts(*arg)
    if block_given?
      puts *arg
      $nivel << Time.new
      yield
      $nivel.pop
    else
      sincro do 
        arg.each do |x|
          print '  ' * $nivel.size
          _puts x
        end
      end
    end
  end
  
  def medir(descripcion=nil, compacto=false)
    duracion = Time.new
    n = nil 
    puts compacto ? "" : "▶︎ #{descripcion}" do 
      n = yield
      duracion = $nivel.last
    end
    puts "#{compacto ? "⦿ "+ descripcion : "◼︎"} #{duracion.info_duracion} #{n ? "(x #{n})" : ""}"
  end
end

module Enumerable
  
  def procesar(titulo = "Procesando...", hilos = 10)
    items = map{|x|x}
    resultado = {}

    inicio, i, n = Time.new, 0, items.size
    medir "#{titulo} [x #{n}#{hilos == 1 ? "" : "/#{hilos}"}]" do 
      queue = Queue.new
      items.each{|item| queue << item }
      hilos.times.map do
        Thread.new do
          until queue.empty?
            item = queue.pop
            resultado[item] = yield(item)
            puts "✧ %3i de %0i (⏳ %s %s)" % [i+=1, n, inicio.falta(i/n.to_f).hora, inicio.duracion.hora] 
          end
        end
      end.each(&:join)
      resultado.count
    end

    items.sort.map{|x| resultado[x]}.compact
  end
  
  def contar
    c = Hash.new(0)
    each{|x| c[x] += 1 }
    c.to_a.sort_by(&:last).reverse
  end
  
  def ranking(descripcion="", tope=nil)
    puts "▶︎ RANKING #{descripcion}. (x#{count})"
    cuenta = self.contar
    ancho  = cuenta.map(&:first).map(&:size).max
    total  = cuenta.map(&:last).suma
    tope ||= cuenta.size
    i, acumulado = 0, 0
    cuenta.first(tope).each do |valor, cantidad| 
      porcentaje = 100.0 * cantidad / total
      acumulado += porcentaje
      puts( " ✧ %3i) %-#{ancho}s  %5i  %3.0f%%  %3.0f%%" % [i +=1, valor, cantidad, porcentaje, acumulado ])
    end
    puts "◼︎"
  end

  def listar(descripcion="")
    puts "▶︎ LISTADO #{descripcion}. (x#{count})"
    cuenta = contar
    ancho  = cuenta.map(&:first).map(&:size).max
    total  = cuenta.map(&:last).suma
    i, acumulado = 0, 0
    cuenta = cuenta.sort_by(&:first)
    cuenta.each do |valor, cantidad| 
      porcentaje = 100.0 * cantidad / total
      acumulado += porcentaje
      puts( " ✧ %3i) %-#{ancho}s  %5i  %3.0f%%  %3.0f%%" % [i +=1, valor, cantidad, porcentaje, acumulado ])
    end
    puts "◼︎"
  end
  
  def empty?
    count == 0
  end
  
  def suma
    inject(&:+)
  end
  
  def promedio
    empty? ? 0 : suma / count
  end
end

class CSV
  def self.name(nombre)
    nombre = nombre.to_s
    nombre += '.csv' unless nombre['.csv']
    nombre
  end
  
  def self.leer(nombre)
    if File.exist?(name(nombre))
      datos  = CSV.read(nombre, 'r:ISO-8859-1:UTF-8', col_sep: ';')
      campos = datos.shift.map(&:to_sym)
      datos.map{|dato| Hash[ campos.zip(dato) ] }
    else
      []
    end
  end
  
  def self.escribir(datos, nombre)
    datos = datos.compact
    campos = datos.map{|x|x.keys}.flatten.uniq
    CSV.open(name(nombre), 'w:ISO-8859-1:UTF-8', col_sep: ';') do |f|
      f << campos
      datos.each{|dato| f << campos.map{|campo|dato[campo]} }
    end
  end
end

class Struct
  
  def self.cargar(datos)
    new.tap{|x| x.cargar(datos)}
  end
  
  def cargar(datos)
    datos = datos.normalizar
    members.each{|k, v| self[k.to_sym] = datos[k.to_sym]}
    normalizar
    self
  end

  def id
    self[members.first]
  end
  
  def normalizar
  end
  
  def valido?
    true
  end
  
  def to_a
    members.map{|campo| self[campo]}
  end
  
  def to_h
    Hash[members.map{|campo| [campo, self[campo]]}].normalizar
  end
end

class Almacen
  include Enumerable
  
  attr_accessor :clase, :datos
  
  def initialize(clase)
    self.clase = clase
    limpiar
    self
  end
  
  def registrar(clase)
    self.clase = clase
  end
  
  def agregar(datos)
    datos = self.clase.new.cargar(datos) if Hash === datos 
    self.datos ||= {}
    self.datos[datos.id] = datos
  end
  
  def limpiar
    self.datos = {}
  end
  
  def leer(nombre=nil)
    nombre = nombre_csv(nombre, :renta)
    puts nombre
    medir "Leer [#{nombre}]", true do 
      CSV.leer(nombre).each{|dato| agregar(dato) }
      count
    end
    self
  end
    
  def escribir(nombre=nil)
    nombre = nombre_csv(nombre, :renta)
    medir "Escribir [#{nombre}]", true do 
      CSV.escribir(map(&:to_h), nombre)
      count
    end
  end
    
  def each
    datos.values.each{|dato|yield dato}
  end
  
  def ids
    self.datos.keys
  end
  
  def campos
    @campos ||= clase.new.members
  end
  
  def campo_id
    campos.first
  end
  
  def nombre_csv(nombre, carpeta=nil)
    nombre ||= clase.name.downcase
    nombre += (nombre['.'] ? '' : '.csv')
    nombre = "#{carpeta}/#{nombre}" if carpeta
    
    nombre
  end
  
  def valores(campo)
    map{|x|x[campo]}
  end
end

puts " 👍🏻 BASE.rb Cargado"