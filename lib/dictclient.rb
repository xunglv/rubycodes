# To change this template, choose Tools | Templates
# and open the template in the editor.

require "dict.rb"

require 'dict'

  dict = DICT.new('dict.org', DICT::DEFAULT_PORT)
  dict.client('a Ruby/DICT client')
  definitions = dict.define(DICT::ALL_DATABASES, 'fucking')

  if definitions
    definitions.each do |d|
      printf("From %s [%s]:\n\n", d.description, d.database)
      d.definition.each { |line| print line }
    end
  end

dict.disconnect