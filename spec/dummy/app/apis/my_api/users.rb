MyApi.define_resource :users do
  relates_to_many :things
end