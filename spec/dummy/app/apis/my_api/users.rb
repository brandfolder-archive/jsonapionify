MyApi.define_resource :users do
  relates_to_many :things do
    add do |context|
      # Set each request related instance's user to the owner instance
      context.request_instances.each { |instance| instance.update user: context.owner_context.instance }
    end

    replace do |context|
      # Find each existing instance in the collection and set its user to nil
      context.collection.each { |instance| instance.update user: nil }

      # Set each request related instance's user to the owner instance
      context.request_instances.each { |instance| instance.update user: context.owner_context.instance }
    end

    remove do |context|
      # Set the request instances to nil
      context.request_instances.each { |instance| instance.update user: nil }
    end
  end

  scope { User }

  attribute :email, types.String, "The email address"
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

  create do |context|
    context.instance.update! context.request_attributes
  end

  update do |context|
    context.instance.update! context.request_attributes
  end

  delete do |context|
    context.instance.destroy
  end

end
