MyApi.define_resource :users do
  relates_to_many :things do
    add
    replace
    remove
  end

  scope { User }

  attribute :email, types.String, "The email address", required: true
  attribute :first_name, types.String, "The last name"
  attribute :last_name, types.String, "The last name"
  attribute :password, types.String, "The password", read: false

  collection do |scope|
    scope.all
  end

  instance do |scope, id|
    scope.find id
  end

  new_instance do |scope|
    scope.new
  end

  list do |context|
    cache context.paginated_collection.cache_key
  end

  read do |context|
    cache context.instance.cache_key
  end

  create
  update
  delete

end
