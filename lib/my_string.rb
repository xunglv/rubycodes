class Person
 end

 pedro = Person.new
 peter = Person.new

 # inject a method in the instances
 def pedro.hello_world; puts "Hola Mundo"; end

 def peter.hello_world; puts "Hello World"; end

 pedro.hello_world #=> Hola Mundo
 peter.hello_world #=> Hello Wo
 puts pedro.respond_to? :hello_world
 puts Person.new.respond_to? :hello_world