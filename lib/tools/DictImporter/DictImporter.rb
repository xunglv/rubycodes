
require "rubygems"
require "active_record"
require "sqlite3"
require 'fileutils'

DB_NAME = "test.db"

file_dir = File.expand_path(File.dirname(__FILE__))
#FileUtils.mkdir file_dir+"/db"

db_path = file_dir+"/db/"+DB_NAME



#

if (!File.exist?(db_path))
  SQLite3::Database.new(db_path)
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :host => "localhost",
  :database => db_path)


ActiveRecord::Schema.define do
    create_table :Vocabularies do |table|
       table.column :keyword, :string
        table.column :meaning, :string
    end

end

class Vocabulary < ActiveRecord::Base
  attr_accessible :keyword, :meaning
end

puts "a1"
employee = Vocabulary.new
employee.keyword = "Fred"

employee.save

puts "a"