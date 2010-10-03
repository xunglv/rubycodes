require 'open-uri'
count=0
while true do
  contents = open('http://xunglv.heroku.com') {|io| io.read}
  if contents.index("navigation round") == nil
    break;
  end
  count+=1
  puts contents
end
puts count;