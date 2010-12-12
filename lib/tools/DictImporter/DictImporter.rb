
require "rubygems"
require "active_record"
require "sqlite3"
require 'fileutils'
require "logger"
require "sequel"
require 'base64'

BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

DB_NAME = "test.db"

@file_dir = File.expand_path(File.dirname(__FILE__))
@db_path = @file_dir+"/db/"+DB_NAME


if (!File.exist?(@db_path))
  SQLite3::Database.new(@db_path)
end

# connect to an in-memory database
@DB = Sequel.connect(:adapter=>'sqlite', :host=>'localhost',
  :database=>@db_path)

#@DB.loggers << Logger.new($stdout)

def dec_val(str_base64)
  tmp = 0
  for i in 0..str_base64.length-1
    pos = BASE64.index(str_base64[i])
    tmp += (64 ** (str_base64.length-i-1))*pos
  end
  return tmp
end


def import_dict_from_file(dict_name, table_name)
  puts "start importing dictionary"

  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      String :keyword, :unique=>true
      String :meaning
    end
    @DB.add_index(table_name, :keyword)
  end


  dict_table = @DB[table_name.to_sym]
  base_path = @file_dir+"/"+dict_name

  #puts base_path
  dict_idx_path = base_path + "/" + "#{dict_name}.index"
  dict_data_path = base_path + "/" +"#{dict_name}.dict"

  count = 0
  File.open(dict_data_path, "r") do |data_file|
    File.open(dict_idx_path, "r") do |idx_file|
      while (line = idx_file.gets)
        count+=1
        pos1 = line.index("\t")
        pos2=line.index("\t",pos1+1)

        keyword = line[0..pos1-1]
        str_entry_offset = line[pos1+1..pos2-1]
        str_entry_len =  line[pos2+1..line.length-2]

        entry_offset = dec_val(str_entry_offset)
        entry_len = dec_val(str_entry_len)
        data_file.seek(entry_offset, IO::SEEK_SET)
        meaning = data_file.read(entry_len)

            
        begin
          dict_table.insert(:keyword=>keyword, :meaning=>meaning.force_encoding("UTF-8"))
        rescue Exception => e
          #puts "cannot import keyword: #{keyword} msg #{e}"
          #puts @DB.from(table_name){id>} # SELECT * FROM items WHERE (id > 2)
          tb_word = @DB['SELECT * FROM ? WHERE keyword = ?',table_name, keyword].first
          #tb_word = dict_table.filter('id = ?',1)
          #puts "test: "+ tb_word[:keyword].to_s
          if tb_word.count > 0
          
            total_meaning = meaning + "\n\n"
            total_meaning += tb_word[:meaning]
            dict_table[:keyword=>keyword] = {:meaning=>total_meaning}
             # puts "keyword #{keyword} meaning: #{meaning} total: #{total_meaning}"
          else
            puts e.to_s
          end

        end

        if count%1000==0
          puts "count: #{count}"
        end
        #if (count==100)
        #  return
        #end
            
      end
    end
  end

  puts "importing done"

end

import_dict_from_file("anhviet", "dict_en_vi")

puts "all done"