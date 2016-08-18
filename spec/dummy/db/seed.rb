require 'faker'

users = 100.times.map do
  User.new(
    first_name: Faker::Name.first_name,
    last_name:  Faker::Name.last_name,
    email:      Faker::Internet.email,
    password:   Faker::Internet.password
  )
end
User.import users
things = User.all.each_with_object([]) do |user, ary|
  new_things = 10.times.map do
    user.things.new(
      name:  Faker::Commerce.product_name,
      color: Faker::Commerce.color,
    )
  end
  ary.concat new_things
end
Thing.import things
