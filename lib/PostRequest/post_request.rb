# This example logs a user in to rubyforge and prints out the body of the
# page after logging the user in.
require 'rubygems'
require 'mechanize'
require 'logger'

# Create a new mechanize object
agent = Mechanize.new { |a| a.log = Logger.new(STDERR) }

# Load the rubyforge website
page = agent.get('http://www.hcmus.edu.vn')
#page = agent.click page.link_with(:text => /Đăng/) # Click the login link
form = page.forms[1] # Select the first form

 form.fields.each { |f| puts f.name }
 
form["username"] = "0512448"
form["passwd"]   = "advance"

# Submit the form
page = agent.submit(form, form.buttons.first)

puts "hello"
puts page.body # Print out the body