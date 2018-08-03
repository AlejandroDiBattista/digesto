require 'pp'
require 'docx_replace'
require 'docx'
require 'fileutils'
require './base'

Origen = '1996.docx'

d = Docx::Document.open(Origen)

Metodos = [:bookmarks, :doc, :document_properties, :each_paragraph, :font_size, :paragraphs, :replace_entry, 
          :save, :styles, :tables, :text, :to_html, :xml, :zip]
puts "METODOS"
puts "   Bookmarks : #{d.bookmarks}"
puts "  Properties : #{d.document_properties}"
puts "   Font Size : #{d.font_size}"
puts "  Paragraphs : #{d.paragraphs.size}"
puts "        Text : #{d.text.size}"
puts "      Styles : #{d.styles.count}"
# puts "        HTML : #{d.to_html}"

# d.paragraphs.each_with_index do |parrafo, i|
#   puts "#{i}) #{parrafo.text}"
# end

doc = DocxReplace::Doc.new(Origen)
doc.replace("Mzna.", "Manzana")
doc.commit("prueba.docx")

