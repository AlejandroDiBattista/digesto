require 'pp'
require 'docx'
require 'fileutils'

Limpias = "/Users/alejandro/Dropbox/limpiar"
LL = './limpias/ale.docx'

module Ordenanzas

  def ubicar(camino, nombre=nil, tipo=nil)
    camino = camino.to_s
    camino = "./#{camino}" unless camino['/']
    if tipo || nombre
      "#{camino}/#{nombre||'*'}.#{tipo||'*'}"
    else
      camino
    end
  end
  
  def listar(carpeta = :ordenanzas, tipo = :docx)
    Dir[ubicar(carpeta, '*', tipo)].sort.delete_if{|x|x['~']}
  end
      
  def nombre(origen, tipo = :docx)
    File.basename(origen, ".#{tipo}")
  end
  
  def carpeta(camino)
    File.dirname(camino)
  end
  
  def leer(origen)
    b = Docx::Document.open(origen)
    b.paragraphs.map(&:text)
  end
  
  def fecha_invalida?(lineas)
    lineas.first[/\AYerba Buena, [0-3][0-9] de \w+ de [12][0-9][0-9][0-9]\Z/i].nil?
  end
  
  def falta_visto_considerando?(lineas)
    e = lineas.count{|x|x['·']}
    lineas = lineas.select{|x| !x['·']}
    o = lineas.index{|x| x[/\AORDENANZA/i]} || 0
    v = lineas.index{|x| x[/\AVISTO:\s*\Z/i]} || 0 
    c = lineas.index{|x| x[/\ACONSIDERANDO:\s*\Z/i]} || 0
    !(o == 1 && v == 2 && c >= 4) && e == 0
  end

  def clasificar(categoria, clasificar: true, limpiar: true)
    inicio = Time.new
    FileUtils.mkdir_p ubicar(categoria)

    # Copiar para analizar
    if clasificar
      puts " ▶︎ Copiando Ordenanzas a [#{categoria}]"
    
      listar(:ordenanzas).each do |origen|
        destino = ubicar(categoria, nombre(origen), :docx)
        unless File.exist?(destino)
          texto = leer(origen)
          if yield(texto)
            puts " > #{nombre(origen)} | [#{texto.first}]"
            FileUtils.copy(origen, destino)
          end
        end
      end
    end
    
    # Recuperar las ordenanzas limpias
    if limpiar
      puts " ▶︎ Recuperando Ordenanzas Limpias de [#{categoria}]"
      listar(categoria).each do |destino|
        texto = leer(destino)
        if !yield(texto)
          origen = ubicar(:ordenanzas, nombre(destino), :docx)
          puts " < #{nombre(origen)} | [#{texto.first}]"
          FileUtils.copy(destino, origen)
          FileUtils.remove destino
        end
      end
    end

    puts " ◼︎ %0.1fs [Hay %i]" % [Time.new-inicio, listar(categoria).size]
  end
end

include Ordenanzas

def verificar_fechas
  clasificar(:fechas, clasificar: true){|texto| fecha_invalida?(texto)}
end

def verificar_visto_considerando
  clasificar(:visto, clasificar: false){|texto| falta_visto_considerando?(texto)}
end

# verificar_fechas()
verificar_visto_considerando()
