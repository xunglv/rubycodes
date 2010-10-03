# To change this template, choose Tools | Templates
# and open the template in the editor.

FN_GIAPHA = "/home/xunglv/Dropbox/giapha.txt"

class Person
  attr_accessor  :name, :birthday, :id, :note, :children
  

end

class Man < Person
  attr_accessor :wife
end

class Woman < Person
  
end

class Generation
  attr_accessor :persons, :fathers, :index

  def  initialize( index)
    @index = index
  end

end

class FamilyAnnals
  attr_accessor :generations
  
end



class GiaphaParser
  def initialize(filename)
    @filename=filename
  end

  def load_from_file
    gen_count=0
    fa = FamilyAnnals.new
    
    File.open(@filename) do |f|
      line = f.gets
      if line.length
        if line[0]=='>'
          if line[1]=='*' #new generation
            gen_count+=1
            generation = Generation.new gen_count
            fa.generation << generation
            #reset all
            person = nil
            father = nil
            
          elseif line[1]=='#' #new person
            person = Person.new
            
          elseif line[1]=='%' #new father
            #father = seek for father
          end
        elsif
          puts ""
        end
      end

    end
  end

  def export_to_html
    

  end
end


gp_parser = GiaphaParser.new(FN_GIAPHA)
gp_parser.export_to_html

puts "it work"

