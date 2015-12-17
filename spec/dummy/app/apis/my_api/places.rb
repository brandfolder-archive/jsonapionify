MyApi.define_resource :places do

  scope { [] }
  collection { |scope| scope }
  instance { OpenStruct.new id: 1 }
  new_instance { OpenStruct.new }

  param :'the-foo', required: true
  param :'just-index', actions: :list

end
