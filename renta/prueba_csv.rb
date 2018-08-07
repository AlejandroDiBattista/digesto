require_relative 'base'
require 'pp'
require 'csv'
require 'open-uri'
require 'pdf-reader'


class Catastro < Struct.new(:padron, :nomenclatura, :categoria, :mat_ord, :alta, :caracter, :domicilio, :responsable_fiscal, :domicilio_fiscal, :codigo_valuacion, :rige_valuacion, :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total, :inscripcion_dominial, :plano_nro, :verificacion_nro, :superficie, :valuacion)  
  def normalizar
    [:valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total,:superficie, :valuacion].each do |campo|
      self[campo] = self[campo].to_importe
    end
    
    self.responsable_fiscal = self.responsable_fiscal.simplificar
    self.padron             = self.padron.to_s
  end
end

def rango(valor, paso)
  (valor / paso).to_i * paso
end

c = Almacen.new(Catastro).leer
p c.count

b = Almacen.new(Boleta).leer
p b.count
puts b.first(3)
#
# # pp c.first(5)
# c.valores(:categoria).ranking("Categorías")
# c.valores(:caracter).ranking("Caracter")
# c.valores(:codigo_valuacion).ranking("Codigos de Valuación")
# c.valores(:alta).map{|x|x.split('/')[1]}.ranking("Mes")
# c.valores(:alta).map{|x|x.split('/')[0]}.ranking("Dia del mes")
# puts "Valoracion YB : $%8.0f" % (a=c.valores(:valuacion).promedio)
# puts "Valoracion TUC: $%8.0f" % (b=c.valores(:valuacion_total).promedio)
# puts "   Terreno TUC: $%8.0f" % (c.valores(:valuacion_terreno).promedio)
# puts "    Mejora TUC: $%8.0f" % (c.valores(:valuacion_mejoras).promedio)
# puts "        PH TUC: $%8.0f" % (c.valores(:valuacion_ph).promedio)
# puts " %0.2f%%" % (100.0*a/b)
# # :valuacion_terreno, :valuacion_mejoras, :valuacion_ph, :valuacion_total,
#
# pp c.valores(:valuacion).map{|x|x.round(-5).to_s.rjust(10)}.listar("Valuacion YB")
# pp c.valores(:valuacion_total).map{|x|x.round(-5).to_s.rjust(10)}.listar("Valuacion TUC")
#
# puts "LOS MAS RICOS... (en Millones $ de Valoración Fiscal )"
# c.select{|x|x.valuacion}.sort_by(&:valuacion).reverse.first(100).each_with_index do |x, i|
#   puts " %4i %4.0fm %-41s [%-7s] [%-51s]" % [i+1, x[:valuacion]/1_000_000, x[:responsable_fiscal][0..40], x[:padron], x[:domicilio][0..50]]
# end
#
# a = c.select{|x|x.valuacion}.sort_by(&:valuacion).reverse.first(100).map{|x|x.to_h.filtrar([:padron,:valuacion,:responsable_fiscal])}
# CSV.escribir(a,'top_100.csv')
#
# puts "JOCKEY CLUB"
# (d=c.select{|x|x.responsable_fiscal[/JOCKEY CLUB/]}).sort_by(&:valuacion).reverse.each_with_index do |x, i|
#   puts " %4i %4.0fm %s" % [i+1, x[:valuacion]/1_000_000, x[:responsable_fiscal]]
# end
# puts "TOTAL : %0.0f" % (d.map(&:valuacion).suma/1_000_000)
#
# medir "100+" do
#   c.valores(:responsable_fiscal).ranking("Los 100 que mas tienen", 100)
# end
#
# d = c.select{|x|x.valuacion_total > 10*x.valuacion}.map{|x| x.to_h.filtrar(:padron, :valuacion, :valuacion_total)}
