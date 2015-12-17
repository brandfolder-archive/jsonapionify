MyApi.define_resource :parties do

  scope { [] }
  collection { |scope| scope }
  instance { OpenStruct.new id: 1 }
  new_instance { OpenStruct.new }

  request_header 'Required-Header', required: true
  request_header 'Action-Header', actions: :list

end
