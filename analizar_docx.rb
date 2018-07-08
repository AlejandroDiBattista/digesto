require 'pp'
require 'docx'
require 'fileutils'
require './base'

module Ordenanzas

  def ubicar(camino, nombre=nil, tipo=nil)
    camino = camino.to_s
    camino = "./#{camino}" unless camino['/']
    if Array === nombre
      nombre.map{|x|"#{camino}/#{x}.#{tipo||:docx}"}
    elsif tipo || nombre
      tipo = :docx if nombre && nombre != "*" && !tipo
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

def extraer_anexo(origen)
  texto = leer(origen)
  texto.select{|x|x[/^ANEXO/i] && x.split.size < 4}
end

def extraer_convenio(origen)
  texto = leer(origen)
  texto.select{|x|x[/^CONVENIO/i] && x.split.size < 4}
end

def separar(lineas)
  # pp lineas
  lineas = lineas.select{|x|!x.split.empty?}
  v = lineas.index{|linea|linea[/^VISTO:$/i]}
  c = lineas.index{|linea|linea[/^CONSIDERANDO:$/i]}
  s = lineas.index{|linea|linea[/SANCIONA.*ORDENANZA.?\s*$/i]}
  e = lineas.index{|linea| linea[/^REGLAMENTO DEL HONORABLE CONCEJO/i]} || lineas.index{|linea| linea[/^ANEXO/i] && linea.split.size < 4 } || lineas.index{|linea|linea[/^(CONVENIO|LIBRO PRIMERO)/i] && linea.split.size < 4} || lineas.size
  { 
    fecha:        lineas[0].split(",").last.strip,
    ordenanza:    lineas[1].split(" ").last.strip,
    visto:        v && c ? lineas[v+1...c] : [],
    considerando: c && s ? lineas[c+1...s] : [], 
    sanciona:     s      ? lineas[s+1...e] : [],
    extra:        e      ? lineas[e..-1]   : []
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

def listar_ordenanzas_nomenclador
	open('./calles.txt').readlines.map{|x|"%04i" % x.chomp.to_i}
end

def copiar_calles
  b = listar_ordenanzas_nomenclador
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
end

def extraer_articulos(origen)
  texto = leer(origen)
  sanciona = separar(texto)[:sanciona]
  numeros = sanciona.select{|x| x[/^ART.?CULO.*:/i]}.map{|x| x.split(':').first.gsub(/ART.?CULO.?/,'')}
  numeros.select{|x|x[/^\D/]}
end

def extraer_cierre(origen)
  texto = leer(origen)
  sanciona = separar(texto)[:sanciona]
  # pp separar(texto)
  # puts "-" * 100
  (sanciona.select{|x| x[/^ART.?CULO.*\W.*:/i]}.last || "")
end

class String
  def simplificar
    strip.gsub('Á','A').gsub('É','E').gsub('Í','I').gsub('Ó','O').gsub('Ú','U').gsub(/\W/,' ').gsub(/\s+/,' ')
  end
end

Excluir    = ['1258', '1299', '0053','0484','0498','0549','0573','0591','0625','0627','0735','0749','0772','0781','0889','0896','0962','1383','1420','1509','1521','1564','2020','1871']
Revisar    = ['1481','1564','1589','1889', '1989', '2078','2100', '2105', '2107', '2108'] - Excluir
Numeracion = ["PRIMERO", "SEGUNDO", "TERCERO", "CUARTO", "QUINTO", "SEXTO", "SÉPTIMO", "OCTAVO", "NOVENO", "DÉCIMO", "DÉCIMO PRIMERO", "DÉCIMO SEGUNDO", "DÉCIMO TERCERO", "DÉCIMO CUARTO", "DÉCIMO QUINTO", "DÉCIMO SEXTO", "DÉCIMO SÉPTIMO", "DÉCIMO OCTAVO", "DÉCIMO NOVENO", "VIGÉSIMO", "VIGÉSIMO PRIMERO", "VIGÉSIMO SEGUNDO", "VIGÉSIMO TERCERO", "VIGÉSIMO CUARTO", "VIGÉSIMO QUINTO", "VIGÉSIMO SEXTO", "VIGÉSIMO SÉPTIMO", "VIGÉSIMO OCTAVO", "VIGÉSIMO NOVENO", "TRIGÉSIMO", "TRIGÉSIMO PRIMERO", "TRIGÉSIMO SEGUNDO", "TRIGÉSIMO TERCERO", "TRIGÉSIMO CUARTO", "TRIGÉSIMO QUINTO", "TRIGÉSIMO SEXTO", "TRIGÉSIMO SÉPTIMO", "TRIGÉSIMO OCTAVO", "TRIGÉSIMO NOVENO", "CUADRAGÉSIMO", "CUADRAGÉSIMO PRIMERO", "CUADRAGÉSIMO SEGUNDO", "CUADRAGÉSIMO TERCERO", "CUADRAGÉSIMO CUARTO", "CUADRAGÉSIMO QUINTO", "CUADRAGÉSIMO SEXTO", "CUADRAGÉSIMO SÉPTIMO", "CUADRAGÉSIMO OCTAVO", "CUADRAGÉSIMO NOVENO", "QUINCUAGÉSIMO", "QUINCUAGÉSIMO PRIMERO", "QUINCUAGÉSIMO SEGUNDO", "QUINCUAGÉSIMO TERCERO", "QUINCUAGÉSIMO CUARTO", "QUINCUAGÉSIMO QUINTO", "QUINCUAGÉSIMO SEXTO", "QUINCUAGÉSIMO SÉPTIMO", "QUINCUAGÉSIMO OCTAVO", "QUINCUAGÉSIMO NOVENO", "SEXAGÉSIMO", "SEXAGÉSIMO PRIMERO", "SEXAGÉSIMO SEGUNDO", "SEXAGÉSIMO TERCERO", "SEXAGÉSIMO CUARTO", "SEXAGÉSIMO QUINTO", "SEXAGÉSIMO SEXTO", "SEXAGÉSIMO SÉPTIMO", "SEXAGÉSIMO OCTAVO", "SEXAGÉSIMO NOVENO", "SEPTUAGÉSIMO", "SEPTUAGÉSIMO PRIMERO", "SEPTUAGÉSIMO SEGUNDO", "SEPTUAGÉSIMO TERCERO", "SEPTUAGÉSIMO CUARTO", "SEPTUAGÉSIMO QUINTO", "SEPTUAGÉSIMO SEXTO", "SEPTUAGÉSIMO SÉPTIMO", "SEPTUAGÉSIMO OCTAVO", "SEPTUAGÉSIMO NOVENO", "OCTAGESIMO", "OCTAGESIMO PRIMERO", "OCTAGESIMO SEGUNDO", "OCTAGESIMO TERCERO", "OCTAGESIMO CUARTO", "OCTAGESIMO QUINTO", "OCTAGESIMO SEXTO", "OCTAGESIMO SÉPTIMO", "OCTAGESIMO OCTAVO", "OCTAGESIMO NOVENO", "NONAGÉSIMO", "NONAGÉSIMO PRIMERO", "NONAGÉSIMO SEGUNDO", "NONAGÉSIMO TERCERO", "NONAGÉSIMO CUARTO", "NONAGÉSIMO QUINTO", "NONAGÉSIMO SEXTO", "NONAGÉSIMO SEPTIMO", "NONAGÉSIMO OCTAVO", "NONAGÉSIMO NOVENO", "CENTÉSIMO", "CENTÉSIMO PRIMERO", "CENTÉSIMO SEGUNDO", "CENTÉSIMO TERCERO", "CENTÉSIMO CUARTO", "CENTÉSIMO QUINTO", "CENTÉSIMO SEXTO", "CENTÉSIMO SÉPTIMO", "CENTÉSIMO OCTAVO", "CENTÉSIMO NOVENO", "CENTÉSIMO DECIMO"].map(&:simplificar)

def analizar_cierre
  puts "▶︎ Analizar CIERRES"
  b = listar(:limpias).map do |origen|
    puts
    a=(extraer_cierre(origen).split(":").last||"").simplificar
    puts " · #{nombre(origen)} > #{a}"
    a
  end
  puts "◼︎"
  b.contar.each{|x,y| puts "%3i #{x}" % y}
end

def analizar_anexo
  puts "▶︎ Analizar ANEXO" 
  b = listar(:limpias).map do |origen|
    puts
    a=extraer_anexo(origen)
    puts " · #{nombre(origen)} > #{a}"
    a
  end.flatten
  puts "◼︎"
  puts '-'*100
  p b.uniq.sort
  puts '-'*100
  b.contar.each{|x,y| puts "%3i #{x}" % y}
end

def analizar_convenio
  puts "▶︎ Analizar CONVENIO" 
  b = listar(:limpias).map do |origen|
    puts
    a=extraer_convenio(origen)
    puts " · #{nombre(origen)} > #{a}"
    a
  end.flatten
  puts "◼︎"
  puts '-'*100
  p b.uniq.sort
  puts '-'*100
  b.contar.each{|x,y| puts "%3i #{x}" % y}
end

# pp separar(leer(ubicar(:limpias, "1712", :docx)))
# puts "-"*100
# pp separar(leer(ubicar(:limpias, "0613", :docx)))
# return
# lista = Revisar.map{|x|ubicar(:limpias,x, :docx)}
lista = listar(:limpias)# - ubicar(:limpias, Excluir)
# lista = lista.select{|x|x.split('/').last >= '1560'}

Extraer = ["ANEXO", "CONVENIO", "REGLAMENTO"]

analizar_cierre