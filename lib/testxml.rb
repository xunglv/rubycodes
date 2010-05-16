# To change this template, choose Tools | Templates
# and open the template in the editor.


require "rexml/document"
require "rexml/xpath"
include REXML
file = File.new( "saigon.kml" )
doc = REXML::Document.new file

#puts doc.root

XPath.each( doc, "//Placemark") { |element| puts element }