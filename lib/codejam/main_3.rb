# To change this template, choose Tools | Templates
# and open the template in the editor.

FN_INPUT="input.txt"
FN_OUTPUT="output.txt"


def input
  line=@fi.gets.strip
  arr=line.split(" ");
  
  @r=arr[0].to_i
  @k=arr[1].to_i
  @n=arr[2].to_i

  line=@fi.gets.strip
  arr=line.split(" ");

  for i in 0..@n-1
    @groups[i]=arr[i].to_i
  end
end


def findtime(rr, start_index)
  money=0
  index=0
  start=start_index

  res={:loopindex=>-1, :loopsteps=>-1, :moneyforaloop=>-1, :money=>-1, :stepstoloopindex=>-1}

  mark =Array.new(@n, {:firsttime=>-1, :money=>-1})

 
  for i in 1..rr
    #time i+1
    if (mark[start][:firsttime]>=0) then
      res[:loopindex]=start
      res[:stepstoloopindex]=mark[start][:firsttime]
      res[:loopsteps]=i-mark[start][:firsttime]-1
      res[:moneyforaloop]=money-mark[start][:money]
      res[:money]=money
      return res
    end
    
    mark[start]={:firsttime=>i-1, :money=>money}
    
    
    s=@groups[start]
    index=start+1
    if (index==@n)
      index=0
    end

    while s+@groups[index]<=@k && index!=start do
      s+=@groups[index]
      index+=1
      if (index==@n)
        index=0
      end
    end
    
    money+=s;
    start=index
    
  end

  res[:money]=money
  return res
  
end

def solve
  #@r=4
  #@k=6
  #@n=4
  #@groups=[1, 4, 2, 1]
  puts "testcase #{@testcase} r #{@r} k #{@k} n #{@n} groups #{@groups.inspect}"

  @money=0
  res = findtime(@r, 0)
  puts res.inspect
  
  if (res[:loopindex]!=-1)
    @money=res[:money]
    #puts @money
    @money +=      ((@r-res[:stepstoloopindex] )/res[:loopsteps] - 1)*res[:moneyforaloop]
    #puts @money
    tmpres=findtime((@r-res[:stepstoloopindex] )%res[:loopsteps], res[:loopindex])
    puts @money
    @money +=tmpres[:money]
  else
    @money=res[:money]
  end

  puts @money
  
end

def output
  @fo.puts "Case ##{@testcase}: #{@money}"
end

def main
  num_testcase=0
  @groups=Array.new(1000,0)
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