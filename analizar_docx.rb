require 'docx'
require 'pp'

module Ordenanzas
  class << self
    def ubicar(patron)
      "./ordenanzas/#{patron}"
    end

    def listar(solo_nombre = false)
      lista = Dir[ubicar('*.docx')].sort
      lista = lista.map{|x| nombre(x)} if solo_nombre 
      lista
    end
    
    def nombre(origen)
      origen.split('/').last.split('.').first
    end
    
    def leer(origen)
      b = Docx::Document.open(origen)
      b.paragraphs.map(&:text)
    end
    
    def procesar
      n = 0
      datos = listar.map do |x|
        print ' ' if n % 10 == 0 
        print '  ' if n % 50 == 0 
        puts if n % 100 == 0 
        puts if n % 500 == 0 
        n += 1
        print '.'
        [leer(x), nombre(x)]
      end
      datos.select{|x| yield(*x) }
    end
    

    def es_fecha(linea)
      !linea[/Yerba Buena, [0-3][0-9] de \w+ de [12][0-9][0-9][0-9]/i].nil?
    end

    def fechas
      listar.map{|x|
        l = leer(x).first
        yield [nombre(x), l, es_fecha(l)]}
      end
    end
end

l = Ordenanzas.listar()
Ordenanzas.fechas do |n, l, c|
  if !c
    p n
    p l
    puts '_' * 100
  end
end

# p Ordenanzas.es_fecha("Yerba Buena, 4 de Enero de 1984")