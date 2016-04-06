MyApi.define_resource :things do

  description <<-markdown
    Describes this resource

    | a | b | c |
    |---|---|---|
    | 1 | 2 | 3 |
  markdown

  attribute :name, types.String, "The name of the things."
  attribute :color, types.String, "The color."
  attribute :secret, types.String, "A super secret.", read: false
  relates_to_one :user do
    replace
  end

  new_instance do |scope|
    scope.new
  end

  list do |context|
    cache context.response_collection.map(&:cache_key).reduce(Digest::SHA2.new, :update).to_s
  end

  read do |context|
    cache context.instance.cache_key
  end

  create
  update
  delete

end
