module BooleanObject
  [true, false].each { |obj| obj.class.include self }
end
