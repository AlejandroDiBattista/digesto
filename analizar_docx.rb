require 'pp'
require 'docx'
require 'fileutils'
require './base'

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
    !(o == 1 && (v == 2|| v == 3) && c >= v+1) && e == 0
  end

  def falta_sanciona_ordenanza?(lineas)
    lineas.select{|x| x[/SANCIONA.*ORDENANZA/]}.empty?
  end
  
  def clasificar(categoria, clasificar: true, limpiar: true, base: nil)
    inicio = Time.new
    FileUtils.mkdir_p ubicar(categoria)
    base ||= :limpias 
    # Copiar para analizar
    if clasificar
      puts " ▶︎ Copiando Ordenanzas a [#{categoria}] (x#{listar(:limpias).size})"
    
      listar(base)[600..-1].each do |origen|
        destino = ubicar(categoria, nombre(origen), :docx)
        puts " . #{nombre(origen)}"
        unless File.exist?(destino)
          texto = leer(origen)
          if yield(texto)
            puts
            puts " > #{nombre(origen)} | [#{texto.first}]"
            FileUtils.copy(origen, destino)
          end
        end
      end
    end
    
    # Recuperar las ordenanzas limpias
    if limpiar
      puts " ▶︎ Recuperando Ordenanzas Limpias de [#{categoria}] (x#{listar(categoria).size})"
      listar(categoria).each do |destino|
        texto = leer(destino)
        if !yield(texto)
          origen = ubicar(base, nombre(destino), :docx)
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

def reemplazar_por_limpias(categoria)
  i =  0
  lista  = listar(categoria).map{|x|nombre(x)}
  limpia = listar(:limpias).map{|x|nombre(x)}

  (lista & limpia).each do |nombre|
    origen  = ubicar(:limpias, nombre, :docx)
    destino = ubicar(categoria, nombre, :docx)
    puts "#{i+=1}) #{origen} =>  #{destino}"
    # FileUtils.copy(origen, destino)
  end
end

def verificar_fechas()
  clasificar(:fechas, clasificar: true){|texto| fecha_invalida?(texto)}
end

def verificar_visto_considerando
  clasificar(:visto, clasificar: false, limpiar: true){|texto| falta_visto_considerando?(texto)}
end

def verificar_sanciona_ordenanza
  clasificar(:sanciona, clasificar: true){|texto| falta_sanciona_ordenanza?(texto)}
end

def verificar_mal_saciona_ordenanza
  clasificar(:mal_sanciona){|texto| !texto.select{|x|x[/^\s*SANCION.*ORDENANZA\s*$/] }.empty?}
end

def verificar_todo
  verificar_fechas
  verificar_visto_considerando
  verificar_sanciona_ordenanza
  verificar_mal_saciona_ordenanza
end

def limpiar_sanciona(texto)
  (texto||"").strip.gsub('  ',' ').gsub(':','').gsub('.','').upcase
end

def separar(lineas)
  v = lineas.index{|linea|linea[/^VISTO:$/i]}
  c = lineas.index{|linea|linea[/^CONSIDERANDO:$/i]}
  s = lineas.index{|linea|linea[/SANCIONA.*ORDENANZA.?\s*$/i]}
  { 
    visto:        v && c ? lineas[v+1...c] : [],
    considerando: c && s ? lineas[c+1...s] : [], 
    sanciona:     s ? lineas[(s+1..-1)] : []
  }
end

def contiene(lineas, valor=nil, &condicion)
  condicion ||= lambda{|x|x[valor]} 
  lineas.index(&condicion)
end

def contiene_visto(lineas, valor=nil, &condicion)
  condicion ||= lambda{|x|x[valor]} 
  separar(lineas)[:visto].index(&condicion)
end

def contiene_considerando(lineas, valor=nil, &condicion)
  condicion ||= lambda{|x|x[valor]} 
  separar(lineas)[:considerando].index(&condicion)
end

def contiene_sanciona(lineas, valor=nil, &condicion)
  condicion ||= lambda{|x|x[valor]} 
  separar(lineas)[:sanciona].index(&condicion)
end

def analizar_estructura
  p "ANALISANDO ESTRUCTURA"
  l = listar(:ordenanzas).map do |origen|
    lineas = leer(origen)
    p origen
    tmp = lineas.select{|x|x[/SANCIONA.*ORDENANZA/] }.map{|x|limpiar_sanciona(x)}
    if tmp.first[/^SANCIONA .* CON FUERZA DE ORDENANZA$/i]
    	p nombre(origen)
    end
    tmp.first
  end
  p "ANALISANDO ORDENANZAS: SANCIONA"
  aa = l.contar
  bb = aa.select{|d,c| !d[/CON.*DEL/]}
  pp bb 
end

#verificar_todo
def listar_ordenanzas_nomenclador
	open('./calles.txt').readlines.map{|x|"%04i" % x.chomp.to_i}
end

a = listar(:limpias).map{|x|nombre(x)}
b = listar_ordenanzas_nomenclador
p b.count
p listar(:calles).count
i = 0 

b.each do |nombre|
	origen  = ubicar(:limpias, nombre, :docx)
	destino = ubicar(:calles, nombre, :docx)
	if File.exist?(origen) #&& ! File.exist?(destino)
		p "#{i+=1} #{origen} => #{destino}"
		FileUtils.copy origen, destino
	end
end
{	
	"0225" => 'transcribir', 
	"0248" => 'ausente', 
	"0783" => 'agregada', 
	"0890" => 'transcribir', 
	"0911" => 'ilegible', 
	"0913" => 'ilegible', 
	"1289" => 'transcribir'
}
# verificar_visto_considerando
# listar(:visto).map{|x|nombre(x)}.each do |destino|
#   origen = ubicar(:ordenanzas, destino, :docx)
#   destino = ubicar(:visto, destino, :docx)
#   p "#{origen} > #{destino}"
#   FileUtils.copy origen, destino
# end
#
#
