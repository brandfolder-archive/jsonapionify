MyApi.define_resource :things do
  extend JSONAPIonify::EnumerableObserver

  description <<-markdown
    Describes this resource
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
  attribute :secret, String, "The name of the things.", read: false
  #attribute :id, String, "The name of the things."

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