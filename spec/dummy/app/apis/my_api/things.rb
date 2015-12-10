MyApi.define_resource :things do
  extend JSONAPIonify::EnumerableObserver

  description <<-markdown
    Describes this resource

    | a | b | c |
    |---|---|---|
    | 1 | 2 | 3 |
  markdown

  id :id
  attribute :name, String, "The name of the things."
  attribute :color, String, "The color."
  attribute :secret, String, "A super secret.", read: false
  relates_to_one :user, resource: :users

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

  index do
  end

end