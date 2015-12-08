require 'pry'

class SampleClass
  def foo
    'first foo'
  end
end

raise unless SampleClass.new.foo == 'first foo'

mod = Module.new do
  def foo
    'second foo'
  end
end

SampleClass.prepend mod

puts SampleClass.new.foo

mod.module_eval do
  instance_methods.each do |m|
    remove_method m
  end
end

puts SampleClass.new.foo

# raise unless SampleClass.new.foo == 'second foo'

