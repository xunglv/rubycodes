# To change this template, choose Tools | Templates
# and open the template in the editor.

FN_GIAPHA = "/home/xunglv/Dropbox/giapha.txt"

class Person
  attr_accessor  :name, :birthday, :id, :note, :children, :alias, :lddate, :father


  def to_s
    "id: #{@id} name:#{@name} note: #{@note}"
  end

end

class Man < Person
  attr_accessor :wifes
  def initialize
    @wifes = Array.new
    @children = Array.new
  end
  def to_s
    "name:#{@name}"
  end
end

class Woman < Person
  
end

class Generation
  attr_accessor :persons, :fathers, :index

  def  initialize( index)
    @index = index
    @persons = Array.new
    @fathers = Array.new
  end

end

class FamilyAnnals
  attr_accessor :generations

  def initialize(filename)
    @generations = Array.new
    @filename=filename
    load_from_file
  end

  def export_to_html
    puts "export to html"
    html = ""
    gen_count=0
    @generations.each do |gen|
        gen_count+=1
        puts "Doi thu #{gen_count}"
        gen.persons.each do |person|
          if person.father.nil?
            
          end
        end

        gen.fathers.each do |father|
          puts father
        end
    end
  end

  def load_from_file
    gen_count=0
    line_index = 0
    File.open(@filename) do |f|
      while (line = f.gets)
          line_index+=1
          #puts "#{line_index}- #{line}"
          
          if line.index("*",0) #new generation
            gen_count+=1

            generation = Generation.new gen_count
            #puts "new generation #{line[2..-1]} generation #{generation}"
            @generations << generation
            #reset all
            person = nil
            father = nil
          elsif line.index('%',0) #new father
            #puts "father #{line[1..-1]}"
            prev_gen = @generations[gen_count-2]
            # puts "prev gen #{prev_gen} persons #{prev_gen.persons} gen_count #{gen_count}"
            found_father = false
            prev_gen.persons.each do  |person_temp|
              #puts "person temp " + person_temp.id.to_s
              if person_temp.id==line[1..-1]
                found_father = true
                # puts "found father"
                father = person_temp
                break
              end
            end

            if !found_father then puts "WARNING!!! type wrong, this father not found: #{line[1..-1]}" end

            generation.fathers << father

            #father = seek for father
          elsif line.index("#",0) #new person
            if (line.index("#-",0))
              person = Woman.new
            elsif
              person = Man.new
              wife=nil
            end

            person.id = line[1..-1];
            person.father = father
            generation.persons << person

            if father
              father.children << person
            end
          elsif line.index("+name:",0)
            puts "person name #{line[6..-1]}"
            person.name = line[6..-1]

          elsif line.index("+lddate:",0)
            puts "ldddate  #{line[8..-1]}"
            person.lddate = line[8..-1]

          elsif line.index("+note:",0)
            current_string = person.note
            puts "note #{line[6..-1]}"
            person.note = line[6..-1]

          elsif line.index("-name:",0)
            puts "wife name #{line[6..-1]}"
            wife = Woman.new
            wife.name = line[6..-1]
            person.wifes <<  wife

          elsif line.index("-lddate:",0)
            puts "wife-lddate #{line[8..-1]}"
            wife.note = line[8..-1]

          elsif line.index("-note:",0)
            puts "wife-note #{line[6..-1]}"
            current_string=wife.note
            wife.note = line[6..-1]
          elsif
            if current_string
              current_string << line
            end
          end
      end
    end


  end
  
end




fa = FamilyAnnals.new(FN_GIAPHA)
html = fa.export_to_html

