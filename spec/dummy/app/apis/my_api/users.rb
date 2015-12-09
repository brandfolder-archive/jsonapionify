MyApi.define_resource :users do
  relates_to_many :things

  scope { User }

  collection do |scope|
    scope.all
  end

  instance do |scope, id|
    scope.find id
  end

  new_instance do |scope|
    scope.new
  end
end