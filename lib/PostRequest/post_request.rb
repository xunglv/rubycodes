require "patron"
sess = Patron::Session.new
    #sess.timeout = 10
    sess.base_url = "http://www.hcmus.edu.vn"
    #sess.headers['User-Agent'] = 'myapp/1.0'
    #sess.enable_debug /tmp/patron.debug
    resp = sess.get("/")

puts resp