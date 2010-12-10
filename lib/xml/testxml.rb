# To change this template, choose Tools | Templates
# and open the template in the editor.


require "rexml/document"
require "rexml/xpath"
include REXML
file = File.new( "./xml/tmp.xml" )
doc = REXML::Document.new file
puts doc.encoding

#puts doc.root

#XPath.each( doc, "//html") { |element| puts element }
puts doc.root.name

File.open("./xml/ids.txt") do |f|
  line = f.gets
  puts line
end