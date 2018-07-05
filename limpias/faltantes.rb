require 'fileutils'
require 'csv'

puts "ANALIZANDO ORDENANZAS FALTANTES"
puts
#Origen = 'C:/Users/usuario/Desktop/ordenanzas'
Limpias = 'C:/Users/usuario/Dropbox/limpiar'

def borrar_temporal(origen=Limpias)
	Dir["#{origen}/~*.docx"].each{|x|File.delete x}
end

def leer_docs
	Dir["#{Limpias}/*.docx"].map{|x|x.split("/").last.split(".").first}.sort.select{|x|x[/[0-9]/]}.map(&:to_i)
end

def leer_registros
	l = {}
	CSV.read("#{Limpias}/ordenanzas.csv",col_sep: ';', headers: true).map{|x| l[x["ordenanza"].to_i] = x["registrado"]== 'Si'}
	l
end

borrar_temporal


t = leer_docs
r = leer_registros
ok = t.select{|x| r[x]}
sr = t.select{|x| not r[x] or r[x].nil?}
st = r.keys.select{|x|r[x]} - t 

puts "OK: (T &  R): #{ok.size}" 
puts "SR: (T & -R): #{sr.size}"
puts "ST: (R & -T): #{st.size}"

#no hay: 2014, 2050, 2051, 2052, 2053, 2063, 2064, 2065, 2073 ,2078, 2079,2080
#no registrado: 2042, 2045, 2059, 2069, 2071, 2072




