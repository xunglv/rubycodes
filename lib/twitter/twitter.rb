require "rubygems"
require "twitter"

CONSUMER_TOKEN="zcMxyjA1eoB2btjQZRpA"
CONSUMER_SECRECT="Vbmg563U7ACV2KmZHHFYBGzk3EDrg4DY0IjHjdPXQI"
ACCESS_TOKEN="19893226-AI59FoF1Qdk1GgKeqKi98rAA0P0AQLxDiPr668KN4"
ACCESS_SECRECT="8WfOl2IcoqYZZdTuMRiJmljMAG56AtXLIdYwK5wn2mo"

# NOT SHOWN: granting access to twitter on website
# and using request token to generate access token
oauth = Twitter::OAuth.new(CONSUMER_TOKEN, CONSUMER_SECRECT)
oauth.authorize_from_access(ACCESS_TOKEN, ACCESS_SECRECT)

client = Twitter::Base.new(oauth)
client.friends_timeline.each  { |tweet| puts tweet.inspect }
client.user_timeline.each     { |tweet| puts tweet.inspect }
client.replies.each           { |tweet| puts tweet.inspect }

client.update('Heeeyyyyoooo from Twitter Gem!')

# Enough about Justin Bieber
#search.clear
