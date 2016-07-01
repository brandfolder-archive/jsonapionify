MyApi.define_resource :users do
  relates_to_many :things, count_attribute: true do
    add
    replace
    remove
  end

  includable :things do |collection|
    collection.includes :user
  end

  attribute :email, types.String, "The email address", required: true
  attribute :first_name, types.String, "The last name"
  attribute :last_name, types.String, "The last name"
  attribute :password, types.String, "The password", read: false

  list do |context|
    cache context.response_collection.map(&:cache_key).reduce(Digest::SHA2.new, :update).to_s
  end

  read do |context|
    cache context.instance&.cache_key
  end

  create
  update
  delete

end
