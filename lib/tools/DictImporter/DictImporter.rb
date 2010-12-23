
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


def dec_val(str_base64)
  tmp = 0
  for i in 0..str_base64.length-1
    pos = BASE64.index(str_base64[i])
    tmp += (64 ** (str_base64.length-i-1))*pos
  end
  return tmp
end

#dict pk,name
#word pk,word
#meaning pk,word,dict,meaning

@dict_table_name = "dicts".to_sym
@word_table_name = "words".to_sym
@meaning_table_name = "meanings".to_sym

def init_database
  
  table_name = "dicts"
  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      String :string_id, :unique=>true
      String :name #, :unique=>true
      #String :meaning

    end
    #@DB.add_index(table_name, :name)
  end

  table_name = "words"
  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      String :word, :unique=>true
      #String :meaning
    end
    @DB.add_index(table_name, :word)
  end

  table_name = "meanings"
  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      Integer :word
      Integer :dict
      String :meaning
      
      #String :meaning
    end
    @DB.add_index(table_name, :word)
    @DB.add_index(table_name, :dict)
  end

  
end

def import_dict_from_file(dict_name, dict_folder)
  puts "start importing dictionary"

  base_path = @file_dir+"/"+dict_folder
  dict_idx_path = base_path + "/" + "#{dict_folder}.index"
  dict_data_path = base_path + "/" +"#{dict_folder}.dict"

  dict_table    = @DB[@dict_table_name];
  dict_id = -1
  begin
    dict_id = dict_table.insert(:name=>dict_name.force_encoding("UTF-8"),
    :string_id=>dict_folder.force_encoding("UTF-8"))
  rescue
    #dict_id = @DB['SELECT * FROM ? WHERE string_id = ?',@dict_table_name, dict_folder].first
    dict_id = dict_table[:string_id=>dict_folder][:id]
    #puts "count not insert dict  #{dict_id}"
  end

  if (dict_id<0)
    puts "unknown error, could not find dict_id"
    return
  end

  word_table    = @DB[@word_table_name];
  meaning_table = @DB[@meaning_table_name];


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

        word_id = -1
        existed_meaning = nil
        begin
          word_id = word_table.insert(:word=>keyword.force_encoding("UTF-8"))
        rescue Exception => e
          word_id = word_table[:word=>keyword][:id]
          existed_meaning = meaning_table[:word=>word_id, :dict=>dict_id]
          if !existed_meaning.nil?
            existed_meaning = existed_meaning[:meaning]
          end
        end

        if (word_id<0)
          puts "unknown error, could not get word id"
          return
        end
          
        begin
          if (!existed_meaning.nil?)
            meaning = existed_meaning + "\n\n" +meaning.force_encoding("UTF-8");
            meaning_table[:dict=>dict_id, :word=>word_id] = {:meaning=>meaning}
            #puts "import tog hop row #{word_id}"
          else
            meaning_table.insert(:dict=>dict_id,:word=>word_id, :meaning=>meaning)
          end

          
        rescue Exception => e
          puts "could not insert meaning #{keyword} e: #{e}"
        end

        if count%1000==0
          puts "count: #{count}"
          #return
        end
            
      end
    end
  end

  puts "importing done"

end

init_database
import_dict_from_file("Vietnamese-English dictionary", "vietanh")
#import_dict_from_file("English-Vietnamese dictionary")


puts "all done"