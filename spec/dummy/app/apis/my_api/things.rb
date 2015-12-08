MyApi.define_resource :things do
  extend JSONAPIonify::EnumerableObserver

  description <<-markdown
    Describes this resource

    | a | b | c |
    |---|---|---|
    | 1 | 2 | 3 |
  markdown

  # DATA STUBS
  instances = []
  observe(instances).added do |items|
    items.each do |item|
      last_item = instances.select(&:id).last
      item.id   = last_item ? last_item.id.to_i + 1 : 1
    end
  end
  10.times.each do
    instances << OpenStruct.new(
      name: Faker::Commerce.product_name
    )
  end
  # END DATA STUBS

  id :id
  attribute :name, String, "The name of the things."
  attribute :secret, String, "A super secret.", read: false

  scope do
    instances
  end

  collection do |scope|
    scope
  end

  instance do |scope, id|
    scope.find { |instance| instance.id == id }
  end

  new_instance do
    OpenStruct.new
  end

  index do
  end

  relates_to_one :user, resource: :users
end