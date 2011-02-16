@file_dir = File.expand_path(File.dirname(__FILE__))

require "rubygems"
require "sqlite3"
require 'fileutils'
require "logger"
require "sequel"
require 'base64'
require "#{@file_dir}/stardict.rb"

BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

DB_NAME = "dev.db"


@db_path = @file_dir+"/dicts_db/"+DB_NAME

@import_by_table_indexes = false

@abc_chars = [""]
for i in 0..25 do
  @abc_chars << ("a".ord + i).chr
end

def create_table_indexes
  path_indexes = @file_dir + "/indexes.txt"
  indexes = []
  File.open(path_indexes, "rt") do |f|
    while (pre = f.gets) do
      indexes << pre.strip
    end
  end
  return indexes
end


def build_vietnamese_chars_hash
  puts "buiding vietnamese hash"
  filename = "vnchars.txt"
  hash = {}
  File.open(@file_dir + "/" + filename )  do |f|
    while line = f.gets do
      chars = line.split(" ")
      if (chars.length>0)
        val = chars[0].strip
        min_ord = 1000000000
        for i in 1..chars.length-1 do
          key = chars[i].strip
          hash[key.to_sym] = val
          if key.ord<min_ord
            min_ord = key.ord
          end
        end
        puts "minchar #{min_ord.chr("UTF-8")} ord #{min_ord}"
      end
    end
  end
  #puts hash
  return hash
end

if (!File.exist?(@db_path))
  SQLite3::Database.new(@db_path)
end


@DB = Sequel.connect(:adapter=>'sqlite', :host=>'localhost',
  :database=>@db_path)

if @import_by_table_indexes then @indexes = create_table_indexes end

@vnchars_hash = build_vietnamese_chars_hash
@dict_table_name = "dicts".to_sym
@meaning_table_name = "meanings".to_sym
@tableid_words = nil
@current_max_id = 0
def init_database
  puts "initing database"
  table_name = "dicts"
  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      String :nameid, :unique=>true
      String :name 
    end
  end

  table_name = "meanings"
  if !@DB.table_exists?(table_name)
    @DB.create_table table_name do
      primary_key :id
      Integer :word_id
      Integer :dict_id
      String :meaning
    end
    @DB.add_index(table_name, :word_id)
    @DB.add_index(table_name, :dict_id)
  end

  if (@import_by_table_index) then
    @indexes.each do |pre|
      if (!@DB.table_exists?(pre))
        create_words_table("words_#{pre}")
      end
      search_key = "max(id)"
      max_id = @DB["select #{search_key} from ?", "words_#{pre}"].first[search_key.to_sym]
      if (!max_id.nil? and max_id>@current_max_id)
        @current_max_id = max_id
      end
    end
  else
    create_words_table("words")
  end
end


def get_word_alias(word)
  word = String.new(word)
  #puts @vnchars_hash
  #puts "word #{word} hash " #{@vnchars_hash.to_s.force_encoding("UTF-8")}"
  i=0
  found = false
  word.each_char do |char|
    val = @vnchars_hash[char.to_sym]
    if (!val.nil?)
      word[i] = val
      found = true
    end
    i+=1
  end
 # puts found
  if (found)
    return word
  else
    return nil
  end
end

def create_words_table(table_name)
  if !@DB.table_exists?(table_name)
          @DB.create_table table_name do
              primary_key :id
              String :word
              String :word_alias
          end
          @DB.add_index(table_name, :word)
          @DB.add_index(table_name, :word_alias)
  end
  return @DB[table_name.to_sym]
end
#



def get_table_name_for_keyword(keyword)
  if (keyword.length<=0)
    return nil
  end

  keyword = keyword.downcase
  search_key = "words_#{keyword}"
  search_col = "max(tbl_name)"

  while(true) do
    row = @DB["select #{search_col} from sqlite_master where type='table' and tbl_name<=? limit 1", search_key].first
    if row[search_col.to_sym].nil?
        return "words_"
    else
        searched_name = row[search_col.to_sym]
        return searched_name
    end
  end
end


def import_list_of_stardicts(dicts_folder)
  dir = Dir.new(dicts_folder)
  dir.each do |filename|

    if (filename == "." or filename == "..")
      next
    end


    import_stardict dicts_folder, filename, false
  end
end

@test = false

def import_stardict(base_dir, dict_folder , is_add_word_alias)

  Dir.chdir("#{base_dir}/#{dict_folder}")

  dict_info = Dir.glob("#{base_dir}/#{dict_folder}/*.ifo")
  dict_name = File.basename(dict_info[0], ".ifo")


  is_babylon_dict = false
  if (dict_name.index("Babylon"))
    puts "bablylon english"
    is_babylon_dict = true;
  end
  
  stardict=StarDict.new(dict_name, is_babylon_dict) #without any extension.


  words = stardict.wordlist.sort
   
  if @test
    puts "in test"
    puts stardict.wordlist.count
    count = 0
    words.each do |entry|
      test = String.new(entry[0])
      puts "entry #{test} len #{test.length}"
      count += 1
      if (count ==1000)
        break
      end
    end
    return
  end

  init_database

  puts "start importing dict. #{stardict.info_data["bookname"]} current max id #{@current_max_id}"
 
  table_dicts = @DB[@dict_table_name.to_sym]
  begin
    dict_id = table_dicts.insert(:nameid=>dict_name, :name=>stardict.info_data["bookname"])
  rescue
    puts "dict imported, skipped"
    return
  end
  table_meanings = @DB[@meaning_table_name.to_sym]
  tablename_words = "words"

  count = 0
  puts "number of words: #{stardict.wordlist.count}"
  words.each do |entry|
    word=entry[0]
    meaning = entry[1]
    word = String.new(word).force_encoding("UTF-8")
    
    if (@import_by_table_indexes)
      tablename_words = get_table_name_for_keyword(word)
    end
      
    if (tablename_words.nil?)
      next
    end

    table_words = @DB[tablename_words.to_sym]
    row = @DB["select id from ? where word=? limit 1",tablename_words,word].first

    
    word_id=nil
    if (row.nil? || row[:id].nil?)
      word_alias = nil
      if (is_add_word_alias)
        word_alias = get_word_alias(word)
      end
      if (@import_by_table_indexs)
        @current_max_id += 1
      else
        @current_max_id = nil
      end
      word_id = table_words.insert(:id=>@current_max_id, :word=>word, :word_alias=>word_alias)
    else
      word_id = row[:id]
    end

    begin
      table_meanings.insert(:dict_id=>dict_id,:word_id=>word_id, :meaning=>meaning)
    rescue Exception => exc
      puts "error when add meaning #{exc}"
    end

    count += 1
    if (count%500==0)
      puts "#{count} words imported"
    end
  end
end


def gen_default_indexes
  File.open("#{@file_dir}/indexes.txt", "wt") do |f|
    f.puts ""
    for i in 0..25 do
      f.puts ("a".ord+i).chr
      for j in 0..25 do
        f.puts "#{("a".ord+i).chr}#{("a".ord+j).chr}"
      end
    end
  end
end


def export_db_indexes
  File.open("#{@file_dir}/indexes.txt", "wt") do |f|
    tables = @DB["select tbl_name from sqlite_master where type='table' and tbl_name like ?", "words_%"]
    tables.each do |hash_name|
      name = hash_name[:tbl_name]
      ss = name.split("_")
      if (ss.length>1)
        f.puts ss[1]
      else
        f.puts ""
      end
    end
  end
end

def show_words_number_by_index
  @indexes.each do |pre|
    search_key = "count(*)"
    numrow = @DB["select #{search_key} from ?", "words_#{pre}"].first[search_key.to_sym]
    if (numrow>1000)
      puts "num #{numrow} table words_#{pre}"
    end
  end
end

def refine_babylon_dict
  count = 0
  for p in 0..@abc_chars.length-1 do
    for q in 0..@abc_chars.length-1 do
      if p==0 && q>0 then next end
      pre_name = @abc_chars[p] + @abc_chars[q]
      tablename = "words_#{pre_name}"
      table = @DB["words_#{pre_name}".to_sym]

      ids = @DB["select id, word from ?", tablename]
      ids.each do |hash_id|
        id = hash_id[:id]
        word = hash_id[:word]
        table[:id=>id] = {:word=>word.sub(/\$[0-9]*\$/,"")}
        count +=1
        if (count%500==0)
          puts "count #{count}"
        end
      end
    end
  end
end


def split_words_table(max_num_row)
  word_rows = @DB["select * from words order by UPPER(word) asc"]
  count=0
  prev_word = ""
  tb_index = ""
  table_words = create_words_table("words_")
  tbcount=0
  word_rows.each do |hash_row|
    word = hash_row[:word]
    #puts "word #{word}"
    if (count>= max_num_row)
      #puts "need to create new table"
      i=0
      while (true) do
        tb_index = word[0..i]
        if (tb_index.upcase>prev_word.upcase)
          puts "word: #{word} tbindex: #{tb_index} preword: #{prev_word}"
          break
        end
        i+=1
        if (i>=word.length)
          puts "an error occur, 2 word equal"
          break
        end
      end
      puts "new table #{tb_index}"
      table_words = create_words_table("words_#{tb_index}")
      count = 0
      tbcount+=1
      puts "#{1000*tbcount} rows processed"
    end
    #puts "insert new row"
    table_words.insert(hash_row)
    count +=1
    prev_word = word
  end
  
end

def write_words_to_txt
  word_rows = @DB["select * from words_ order by UPPER(word) asc"]
  File.open("./000.txt", "wt") do |f|
  word_rows.each do |hash_row|
    f.puts hash_row[:word]
  end
  end
  puts "write is done"
end

 
#gen_default_indexes
#import_stardict "Longman-img", false
#import_stardict "dictd_www.dict.org_gcide", false
#import_stardict "#{@file_dir}/dicts/eng", "stardict-freedict-hun-eng-2.4.2", false
#import_stardict "dictd_viet-viet", true
#import_stardict "dictd_viet-phap", true
#import_stardict "wordnet", false
#import_stardict "star_phapviet", false
#import_stardict "dictd_anh-viet", false
#import_stardict "BabylonEnglish",  false


#refine_babylon_dict
#init_database

#puts "ắ".length #> "ư"

import_list_of_stardicts "#{@file_dir}/dicts/enasia"


#show_words_number_by_index
#write_words_to_txt

#split_words_table 1000

#export_db_indexes



puts "all done"


