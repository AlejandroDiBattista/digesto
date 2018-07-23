require 'pp'

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
  def limpiar_espacios
    gsub(/\s+/,' ').strip
  end
  
  def to_importe
    self.gsub(',','.').gsub(/[^0-9.]/,'').to_f
  end

  def to_id
    gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
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
  
  def medir(descripcion=nil)
    duracion = Time.new
    puts "▶︎ #{descripcion}" do 
      yield
      duracion = $nivel.last
    end
    puts "◼︎ #{duracion.info_duracion}"
  end
end

module Enumerable
  def procesar(titulo="Procesando...", hilos=10)
    items = map{|x|x}
    resultado = {}

    inicio, i, n = Time.new, 0, items.size
    medir "#{titulo} [x #{n}#{hilos==1 ? "" : "/#{hilos}"}]" do 
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
    end

    items.sort.map{|x| resultado[x]}
  end
  
  def contar
    uniq.map{|x| [x, count(x)]}.sort_by(&:last).reverse
  end
  
  def ranking(descripcion="")
    puts "▶︎ RANKING #{descripcion}. (x#{count})"
    cuenta = contar
    ancho  = cuenta.map{|x| x.first.size}.max
    total  = cuenta.map{|x| x.last}.inject(&:+)
    i, acumulado = 0, 0
    cuenta.each do |valor, cantidad| 
      porcentaje = 100.0 * cantidad / total
      acumulado += porcentaje
      puts( " ✧ %3i) %-#{ancho}s  %5i  %3.0f%%  %3.0f%%" % [i +=1, valor, cantidad, porcentaje, acumulado ])
    end
    puts "◼︎"
  end
end

class Hash
  def normalizar
    keys.each do |x|
      if String === x 
        self[x.to_sym] = self[x]
        delete(x)
      end
    end
    self
  end
  
  def filtrar(campos)
    borrar = keys - campos
    borrar.each{|k| delete k}
    self
  end
end

class Struct
  def cargar(datos)
    datos = datos.normalizar
    members.each{|k, v| self[k.to_sym] = datos[k.to_sym]}
    normalizar
    self
  end
  
  def normalizar
  end
end

