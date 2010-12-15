
require "rubygems"
require "active_record"
require "sqlite3"
require 'fileutils'
require "logger"
require "sequel"
require 'base64'

DB_NAME = "ratp.sqlite"

@file_dir = File.expand_path(File.dirname(__FILE__))
@db_path = @file_dir+"/db/"+DB_NAME

# connect to an in-memory database
@DB = Sequel.connect(:adapter=>'sqlite',:database=>@db_path)


def convert_db
  puts "start converting"


  hash = {
    :geolocatedstation => [:station,:direction],
    :direction => [:line],
    :line=>[:network]
  }

  tmp_table=:tmp_xyz
  hash.each do |table_name, column_names|
    column_names.each do |column_name|
      puts "table #{table_name} col #{column_name}"
      table = @DB[table_name]
      @DB.add_column table_name, tmp_table, :integer
      rows = table.select_all
      count=0
      for row in rows
        pk = row[:pk]
        old_val = row[column_name]
        tmps = old_val.split("-")
        if (tmps.count>0)
          val = tmps[1].to_i
          table[:pk=>pk] = {tmp_table=>val}
        end
        count+=1
        puts "current row #{count}"
      end

      @DB.drop_column table_name.to_sym, column_name.to_sym
      @DB.rename_column(table_name, tmp_table, column_name)
      #vaccuum
    end
  end

  puts "converting done"

end

convert_db

puts "all done"