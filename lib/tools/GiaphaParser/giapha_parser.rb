# To change this template, choose Tools | Templates
# and open the template in the editor.

require "rexml/document"
require "rexml/xpath"
require "singleton"
include REXML


FN_GIAPHA = "/home/xunglv/Dropbox/giapha.txt"


class Person
  attr_accessor  :name, :bdate, :id, :note, :children, :alias, :ddate, :father, :gender
  def to_s
    "id: #{@id} name:#{@name} note: #{@note}"
  end

  def get_lovers_element
    return Element.new "div"
  end

  def to_tr_element
    tr_ele = Element.new "tr"

    td_ele = tr_ele.add_element "td"
    td_ele.text = @name
    td_ele.attributes["style"] = "width:200px"

    td_ele = tr_ele.add_element "td"
    td_ele.text = @gender

    td_ele = tr_ele.add_element "td"
    td_ele.text = @bdate

    td_ele = tr_ele.add_element "td"
    td_ele.add_element self.get_lovers_element
    td_ele.attributes["style"] = "width:200px"

    td_ele = tr_ele.add_element "td"
    td_ele.text = @ddate

    td_ele = tr_ele.add_element "td"
    td_ele.text = @note

    return tr_ele
  end

end


class Man < Person
  attr_accessor :wifes
  def initialize
    @wifes = Array.new
    @children = Array.new
    @table_column_titles = ["Ho Ten", "Phai", "Sinh", "Vo/Chong", "Mat", "Ghi chu"]
    @gender = "Nam"
  end
  def to_s
    "name:#{@name}"
  end

  def get_lovers_element
    self.wifes_to_div_element
  end

  def wifes_to_div_element
    ele = Element.new "div"
    @wifes.each  do |wife|
      ele.add_element wife.to_div_element
    end
    ele
  end


  def to_tr_element_string
    self.to_tr_element.to_s
  end

  def to_table_element # to a <tr> tag
    table_ele = Element.new "table"
    table_ele.attributes["border"]="1px"
    table_ele.attributes["style"] = "width:800px"
    table_ele.attributes["bordercolor"]="red"

    #create header
    tr_ele = table_ele.add_element "tr"
    tr_ele.attributes["bgcolor"]="yellow"
    @table_column_titles.each do |col_title|
        td_ele = tr_ele.add_element "td"
        td_ele.text = col_title
    end

    #add parent
    @children.each do |child|
        tr_ele = child.to_tr_element
        table_ele.add_element tr_ele
    end

    table_ele

  end

  def to_div_element
    div_ele = Element.new "div"
    title_ele = div_ele.add_element "i"
    title_ele.text = "#{@name} sinh: "
    div_ele.add_element self.to_table_element
    div_ele
  end
end

class UnknownMan < Man
  def initialize
    super
    @name="Khong biet cha"
  end
end

class Woman < Person
  attr_accessor :husbands
  def initialize
    @gender = "Nu"
  end
  def to_div_element
    ele = Element.new "div"
    br_ele = Element.new "br"

    if (@name)
      ele.add_text "Ten: #{@name}"
      ele.add_element br_ele
    end

    if (@bdate)
      ele.add_text "Sinh: #{@bdate}"
      ele.add_element br_ele
    end

    if (@ddate)
      ele.add_text "Ky: #{@ddate}"
      ele.add_element br_ele
    end

    if (@note)
      ele.add_text "Ghi chu: #{@note}"
      ele.add_element br_ele
    end
    return ele
  end
  
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

  def export_to_html(file_name)
    File.open(file_name, 'w') do |f|
      #puts "file #{f}"
      f.write(self.to_html_element.to_s)

    end
  end

  def to_html_element
    puts "export to html"
    html_ele = Element.new "html"
    html_ele.attributes["xmlns"]="http://www.w3.org/1999/xhtml"
    html_ele.add_element "head"
    body_ele = html_ele.add_element "body"
    div_ele = body_ele.add_element "div"
    #div_ele.attributes["style"]="width: 800px; background-color:gray"
    
    gen_count=0
    @generations.each do |gen|
        gen_count+=1

        title_ele = div_ele.add_element "h4"
        title_ele.text = "Doi thu #{gen_count}"

        gen.fathers.each do |father|
          div_ele.add_element father.to_div_element
        end
    end
   # puts html_ele.to_s
    html_ele
  end

  def load_from_file
    gen_count=0
    line_index = 0
    current_string = nil
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

            if (line.strip.length>1)
              found_father = false
              prev_gen.persons.each do  |person_temp|
                #puts "person temp " + person_temp.id.to_s
                if person_temp.id==line[1..-2]
                  found_father = true
                  # puts "found father"
                  father = person_temp
                  break
                end
              end
               if !found_father then puts "WARNING!!! type wrong, this father not found: #{line[1..-1]}" end
            elsif
              father = UnknownMan.new
            end
            generation.fathers << father

          elsif line.index("#",0) #new person
            if (line.index("#-",0))
              person = Woman.new
            elsif
              person = Man.new
              wife=nil
            end

            person.id = line[1..-2];
            person.father = father
            generation.persons << person
            father.children << person if father
          elsif line.index("+name:",0)
            #puts "person name #{line[6..-2]}"
            person.name = line[6..-2]
          elsif line.index("+alias:",0)
           # puts "person name #{line[7..-2]}"
            person.alias = line[7..-2]

          elsif line.index("+ddate:",0)
            #puts "ddate  #{line[7..-2]}"
            person.ddate = line[7..-2]

          elsif line.index("+note:",0)
            person.note = line[6..-1]
            current_string = person.note
            #puts "note #{line[6..-1]} current_string #{current_string}"
            

          elsif line.index("-name:",0)
            wife = Woman.new
            wife.name = line[6..-2]
            person.wifes <<  wife
          elsif line.index("-alias:",0)
            wife.alias = line[7..-2]

          elsif line.index("-ddate:",0)
           # puts "wife-lddate #{line[7..-2]}"
            wife.ddate = line[7..-2]

          elsif line.index("-note:",0)
            #puts "wife-note #{line[6..-1]}"
            wife.note = line[6..-1]
            current_string=wife.note
            
          elsif
            
            if current_string
              #puts "current string #{current_string} line #{line}"
               current_string << line
              
            end
          end
      end
    end



  end
  
end




fa = FamilyAnnals.new(FN_GIAPHA)
fa.export_to_html("./test.xhtml")


puts "exported"