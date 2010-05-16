#!/usr/bin/ruby

FN_PROCESS="gedit"
PROCESS_NAME="gedit"

INTERVAL_TIME=3 #(seconds)

def background_every_n_seconds(n)
  loop do
    before = Time.now
    yield
    interval = n-(Time.now-before)
    sleep(interval) if interval > 0
  end
end


background_every_n_seconds(INTERVAL_TIME) {
  begin
     s = IO.popen("ps -A") {|f| f.read }

     s = s.downcase

     if (s.index(PROCESS_NAME.downcase)==nil)
        Thread.new{
          system(FN_PROCESS)
          puts "da thoat process"
        }

        puts "sau khi chay"
      else
        puts "da chay san roi"
      end
  rescue

  end
}



      
  