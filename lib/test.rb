def quit?
  begin
    # See if a 'Q' has been typed yet
    while c = STDIN.read_nonblock(1)
      puts "I found a #{c}"
      return true if c == 'Q'
    end
    # No 'Q' found
    false
  rescue Errno::EINTR
    puts "Well, your device seems a little slow..."
    false
  rescue Errno::EAGAIN
    # nothing was ready to be read
    puts "Nothing to be read..."
    false
  rescue EOFError
    # quit on the end of the input stream
    # (user hit CTRL-D)
    puts "Who hit CTRL-D, really?"
    true
  end
end

loop do
  puts "I'm a loop!"
  puts "Checking to see if I should quit..."
  break if quit?
  puts "Nope, let's take a nap"
  sleep 5
  puts "Onto the next iteration!"
end

puts "Oh, I quit."