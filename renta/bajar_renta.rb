require_relative 'base'
require 'open-uri'
require 'pdf-reader'

module Web  
  
  def boleta(nro, verboso=false)
    url = "http://boletas.yerbabuena.gob.ar//imprimir.php?id=#{nro}"
    puts(url) if verboso

    reader = PDF::Reader.new(open(url))
    lineas = reader.pages.first.text.split("\n").first(30)
    if verboso
      lineas.each_with_index do |linea, i|
        print " %3i) " % (i)
        puts "[#{linea}] > #{linea.split}"
      end
    end
    lineas = lineas.map{|x|x.split}
    datos  = { padron: lineas[7][2], valuacion: lineas[29][2].importe, boleta: nro, 
               importe: lineas[9][-2].importe, mes: lineas[7][-3].numero, año: lineas[7][-1].numero }
    pp(datos) if verboso

    datos
  end
  
  def catastro(padron, verboso=false)
    url = "http://190.3.119.122:85/frmInfoParcelageo.asp?txtpadron=#{padron}"
    puts(url) if verboso

    texto = open(url).read.limpiar_espacios
    texto = texto.gsub('SUPERFICIE PROPIA SEGUN PLANO:', 'superficie:')
    texto = texto.gsub('SUPERFICIE SEGUN PLANO:', 'superficie:')
  
    lineas = texto.split('&')
    pp(lineas) if verboso
  
    lineas = lineas.select{|x|x[":"]}.map{|x|x.split(':')}.map{|a,*b| [id(a).to_sym, b.join(' ').limpiar_espacios]}
    lineas = lineas.delete_if{|nombre, valor| nombre[/propietario_legal/]}
    lineas = lineas.delete_if{|nombre, valor| nombre[/hijuela/]}
  
    return nil if lineas.size == 0 
  
    datos = Hash[lineas]
    datos.each{|k, v| datos[k] = datos[k].to_importe if k[/valuacion_/]}
    datos[:alta]             = limpiar_fecha(datos[:alta])
    datos[:domicilio]        = limpiar_domicilio(datos[:domicilio])        if datos[:domicilio]
    datos[:domicilio_fiscal] = limpiar_domicilio(datos[:domicilio_fiscal]) if datos[:domicilio_fiscal]
    datos[:superficie]       = datos[:superficie].split.first.to_importe   if datos[:superficie]

    datos
  end
  
end
include Web

def leer_valuaciones()
  datos  = CSV.leer('boletas.csv')
  salida = {}
  datos.each do |x| 
    padron = x[:padron].to_s
    valor  = x[:valuacion].to_importe
    salida[padron] = valor
  end
  salida
end

def bajar_yb(rango)
  viejos = CSV.leer('boletas.csv')
  
  nuevos = rango.procesar("Bajando Boletas", 50){|nro| boleta(nro)}
  datos  = (nuevos + viejos).uniq
  datos  = datos.select{|x| !x[:padron][/\D/]}

  CSV.escribir(datos, 'boletas.csv')
  padrones = datos.map{|x| x[:padron] }
end

def bajar_boletas(inicial, cantidad=10_000)
  final = cantidad < 100_000 ? inicial + cantidad : final = cantidad
  puts "Bajando #{final-inicial} boletas"
  paso = 10_00
  (inicial..final).step(paso) do |n|
    puts n
    bajar_yb(n..(n+paso))
  end
end

def limpiar_domicilio(texto)
  texto = texto.gsub("Piso Dpto",'Dpto')
  texto = texto.gsub("Dpto Block",'Block')
  texto = texto.gsub("Block Mz",'Mz')
  texto = texto.gsub("Mz Casa",'Casa')
  texto = texto.gsub("Casa/Lote -",'-')
end

def limpiar_fecha(fecha)
  d, m, a = *fecha.split("/")
  unless (1..12) === m.to_i 
    i = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"].index(m)
    m = "%02i" % (i+1) if i 
  end
  [d, m, a].join('/')
end

def bajar_catastro(nombre='catastro.csv', max=1000)
  valuaciones = leer_valuaciones()
  anterior = CSV.leer(nombre)

  padrones = valuaciones.keys - anterior.map{|x|x[:padron]}
  puts "Hay #{padrones.size}"

  datos = padrones.first(max).procesar("Catastro", 50){|padron| catastro(padron)}.compact
  datos.each{|d|d[:valuacion] = valuaciones[d[:padron]] || 0}
  
  CSV.escribir(datos+anterior, nombre)
end

# bajar_boletas 9_260_000, 9_400_000

# a = CSV.leer('catastro.csv')
# p a.map{|x|x[:valuacion]}.sort.first(100)

boleta(9182130, true)