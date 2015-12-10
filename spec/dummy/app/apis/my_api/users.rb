MyApi.define_resource :users do
  relates_to_many :things

  scope { User }

  attribute :email, String, "The email address"
  attribute :first_name, String, "The last name"
  attribute :last_name, String, "The last name"
  attribute :password, String, "The password", read: false

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
