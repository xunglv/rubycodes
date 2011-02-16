# To change this template, choose Tools | Templates
# and open the template in the editor.



def import_dict_from_file_hnd(dict_name, dict_folder)
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
          ch = keyword[0].upcase
          kind = 0
          if (ch<='Z' and ch >= 'A')
            kind = ch.getbyte(0) - 64
          end
          word_id = word_table.insert(:word=>keyword.force_encoding("UTF-8"), :kind=>kind)
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
            meaning = existed_meaning + "\n\n" + meaning.force_encoding("UTF-8");
            meaning_table[:dict=>dict_id, :word=>word_id] = {:meaning=>meaning}
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

def add_kind_to_words_table
  words_table    = @DB[@word_table_name];
  rows = words_table.select_all
  count=0
  for row in rows
    word = row[:word]
    id = row[:id]

    ch = word[0].upcase
    kind = 0
    #puts "xxx: "+ch.class.to_s
    if (ch<='Z' and ch >= 'A')
      kind = ch.getbyte(0) - 64
    end

    words_table[:id=>id] = {:kind=>kind}

    count+=1

    if (count%500==0)
      puts count
    end
  end
end

def split_words_table
  word_tables = []
  for i in 0..26
    table_name = "words_" + i.to_s
    if !@DB.table_exists?(table_name)
      @DB.create_table table_name do
        primary_key :id
        String :keyword
      end
      @DB.add_index(table_name, :keyword)
    end

    word_table = @DB[table_name.to_sym]
    word_tables << word_table
  end

  puts word_tables.count

  word_table = @DB[:words]
  max_row = 241668
  for i in 1..max_row
    row = word_table[:id=>i]
    kind = row[:kind]
    new_table_name = "words_#{kind}"
    #puts new_table_name
    @new_table = @DB[new_table_name.to_sym]
    @new_table.insert(:id=>row[:id], :keyword=>row[:word])

    if (i%500==0)
      puts "table name: #{new_table_name} row #{i}"
    end
  end
end




def add_words_alias_for_vietnamese
  count = 0
  for i in 0..26
    table_name = "words_"+i.to_s
    #puts table_name
    word_table = @DB[table_name.to_sym]
    word_rows = word_table.all
    #puts "#{i} #{word_rows[0]}"

    begin
      @DB.add_column table_name, :keyword_alias, :text
    rescue
      puts "column existed"
    end

    word_rows.each do |row_hash|
      count+=1
      word = row_hash[:keyword]
      id = row_hash[:id]
      keyword_alias = String.new(word)
      should_add = get_word_alias(keyword_alias)
      #puts "#{keyword_alias} word #{word}"
      if (should_add)
        word_table[:id=>id]={:keyword_alias=>keyword_alias}
      end

      if count%500==0
        puts count
      end
    end


  end

end

def next_pre_char(ch)
  if (ch<'a')
    return "a"
  elsif (ch>='a' and ch<'z')
    return (ch.ord+1).chr
  elsif (ch >= 'z')
    return nil
  else
    raise "next_pre_char: invalid char"
  end
end

def prev_pre_char(ch)
  if (ch>'z')
    return 'z'
  elsif (ch>='a' and ch<='z')
    return ch
  elsif (ch >= ' ')
    return ' '
  else
    raise "prev_pre_char: invalid char"
  end
end

def get_next_pre(pre, word)

  search_col = "max(word)"
  tablename = "words_#{pre}"
  row = @DB["select #{search_col} from ?",tablename].first
  word_max_pre = row[search_col.to_sym]
  i = [pre.length-1, word.length-1].min
  pre_new = nil
  while (i>=0 && pre[i]==word[i]) do i-=1 end
  if (i<0) then
    pre_new = pre+" "
  else
    #if (last_char.nil?) then last_char = "z" end
    last_char = prev_pre_char(word[i])
    pre_new = pre[0..i]
    pre_new[-1] = last_char
    #puts "pre #{pre} word #{word} lastchar #{last_char} prelastchar #{word[pre.length-1]}"
  end

  puts "word #{word} pre #{pre} pre_new #{pre_new}"

end

def dec_val(str_base64)
  tmp = 0
  for i in 0..str_base64.length-1
    pos = BASE64.index(str_base64[i])
    tmp += (64 ** (str_base64.length-i-1))*pos
  end
  return tmp
end