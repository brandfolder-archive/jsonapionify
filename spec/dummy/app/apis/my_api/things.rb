MyApi.define_resource :things do

  description <<-markdown
    Describes this resource

    | a | b | c |
    |---|---|---|
    | 1 | 2 | 3 |
  markdown

  id :id
  attribute :name, types.String, "The name of the things."
  attribute :color, types.String, "The color."
  attribute :secret, types.String, "A super secret.", read: false
  relates_to_one :user, resource: :users do
    replace do |context|
      context.owner_context.instance.update! user: context.request_instance
    end
  end

  scope do
    Thing
  end

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
    context.instance.update context.request_attributes
  end

  update do |context|
    context.instance.update context.request_attributes
  end

  delete do |context|
    context.instance.destroy
  end

end
