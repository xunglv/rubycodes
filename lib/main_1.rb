# To change this template, choose Tools | Templates
# and open the template in the editor.

FN_INPUT="input.txt"
FN_OUTPUT="output.txt"


def input
  line=@fi.gets.strip
  nk=line.split(" ");
  @n=nk[0].to_i
  @k=nk[1].to_i
end

def power(a,n)
  p=1
  n.times  { p*=a };
  return p;
end

def solve

  snappers = Array.new(@n+1, 0)
  snappers[0]=1;
  
  presnappers=Array.new(snappers)
  
  if @k==0 then
    @result="OFF"
    return
  end
  @result="OFF"

  puts @n
  puts @k
  puts @testcase

  
  t=power(2, @n)
  puts t
  if (@k+1).divmod(t)[1]==0
    @result="ON"
  end
  
#  for i in 1..@k do
#    j=1
#    while presnappers[j-1]==1 && j<=@n
#      snappers[j]=1-snappers[j]
#      j+=1
#    end
#
#    found_off=false
#    for v in 1..@n do
#      if snappers[v]==0 then found_off=true end
#    end
#
#
#    presnappers=Array.new(snappers)
#    puts snappers.inspect
#    if (!found_off)
#      puts i
#      return
#    end
#  end

  

  

#  found_off=false
#  for i in 1..@n do
#    if snappers[i] == 0 then found_off=true end
#  end
#
#  @result="ON"
#  if found_off then @result = "OFF"  end
end

def output
  @fo.puts "Case ##{@testcase}: #{@result}"
end

def main
  num_testcase=0
  @n=0
  @k=0
  File.open(FN_OUTPUT, "w") do |fo|
    @fo=fo
    File.open(FN_INPUT, "r") do |fi|
      @fi=fi
      num_testcase = fi.gets.strip.to_i
      for i in 1..num_testcase
        @testcase=i
        input()
        solve()
        output()
      end
    end

  end

end

main