require_relative 'base'
require 'pp'
require 'csv'
require 'open-uri'
require 'pdf-reader'

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
    nombre = nombre_csv(nombre, 'renta')
    medir "Leer [#{nombre}]", true do 
      CSV.leer(nombre).each{|dato| agregar(dato) }
      count
    end
  end
    
  def escribir(nombre=nil)
    nombre = nombre_csv(nombre)
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

class Boleta < Struct.new(:padron, :valuacion, :boleta)
  def normalizar
    self.padron    = padron.to_s
    self.valuacion = valuacion.to_f
    self.boleta    = boleta.to_i
  end
  
  def valido?
    self.valuacion > 0 
  end
end

CamposCatastro = [:padron, :nomenclatura, :categoria, :mat_ord, :alta, :caracter, :domicilio, :responsable_fiscal, :domicilio_fiscal, :codigo_valuacion, :rige_valuacion, :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total, :inscripcion_dominial, :plano_nro, :verificacion_nro, :superficie, :valuacion]
class Catastro < Struct.new(*CamposCatastro)
  
  def normalizar
    [:valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total,:superficie, :valuacion].each do |campo|
      self[campo] = self[campo].to_importe
    end
    
    self.responsable_fiscal = self.responsable_fiscal.gsub(/[^a-zñ0-9 ]/i, '')
    self.padron = self.padron.to_s
  end
  
end

# b = Almacen.new(Boleta)
# b.leer('boletas')
# p b.count
# pp b.first(5)

def rango(valor, paso)
  (valor / paso).to_i * paso
end

c = Almacen.new(Catastro)
puts "--"
c.leer('catastro')
p c.count
# pp c.first(5)
c.valores(:categoria).ranking("Categorías")
c.valores(:caracter).ranking("Caracter")
c.valores(:codigo_valuacion).ranking("Codigos de Valuación")
c.valores(:alta).map{|x|x.split('/')[1]}.ranking("Mes")
c.valores(:alta).map{|x|x.split('/')[0]}.ranking("Dia del mes")
puts "Valoracion YB : $%8.0f" % (a=c.valores(:valuacion).promedio)
puts "Valoracion TUC: $%8.0f" % (b=c.valores(:valuacion_total).promedio)
puts "   Terreno TUC: $%8.0f" % (c.valores(:valuacion_terreno).promedio)
puts "    Mejora TUC: $%8.0f" % (c.valores(:valuacion_mejoras).promedio)
puts "        PH TUC: $%8.0f" % (c.valores(:valuacion_ph).promedio)
puts " %0.2f%%" % (100.0*a/b)
# :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total,

pp c.valores(:valuacion).map{|x|x.round(-5).to_s.rjust(10)}.listar("Valuacion YB")
pp c.valores(:valuacion_total).map{|x|x.round(-5).to_s.rjust(10)}.listar("Valuacion TUC")

puts "LOS MAS RICOS... (en Millones $ de Valoración Fiscal )"
c.select{|x|x.valuacion}.sort_by(&:valuacion).reverse.first(100).each_with_index do |x, i|
  puts " %4i %4.0fm %-41s [%-7s] [%-51s]" % [i+1, x[:valuacion]/1_000_000, x[:responsable_fiscal][0..40], x[:padron], x[:domicilio][0..50]]
end

a = c.select{|x|x.valuacion}.sort_by(&:valuacion).reverse.first(100).map{|x|x.to_h.filtrar([:padron,:valuacion,:responsable_fiscal])}
CSV.escribir(a,'top_100.csv')

puts "JOCKEY CLUB"
(d=c.select{|x|x.responsable_fiscal[/JOCKEY CLUB/]}).sort_by(&:valuacion).reverse.each_with_index do |x, i|
  puts " %4i %4.0fm %s" % [i+1, x[:valuacion]/1_000_000, x[:responsable_fiscal]]
end
puts "TOTAL : %0.0f" % (d.map(&:valuacion).suma/1_000_000)

medir "100+" do 
  c.valores(:responsable_fiscal).ranking("Los 100 que mas tienen", 100)
end

d = c.select{|x|x.valuacion_total > 10*x.valuacion}.map{|x| x.to_h.filtrar(:padron, :valuacion, :valuacion_total)}

# CSV.escribir(d, :padron_valuacion)
"rueda maria lia"

#p e=c.select{|x|x[:responsable_fiscal][/rueda/i]}
# pp e