## Apis

class ExampleApi < JSONAPIonify::Base

end

## Resources
# Resources are what the api serves up to represent data within your application.

# **define_resource**<br />
# Calling `define_resource` on an Api class will define a resource.
# This will not only define the resource, but add routes to the api to access
# the resouce. By default only the **`read`** route (`GET /{resource}/{id}`) is
# added when you define a resource. Additional routes will have to be specified
# in the resource definition.
ExampleApi.define_resource :users do

  ### Resource Setup
  # Resources require a default setup that defines how the resource interacts
  # with the data model.

  # **scope**<br />
  # Scope defines the model/object that the resource will represent. By default,
  # it will try to find a class that matches the resource name. In this example
  # resource, `:users` would implicitly look for a `User` class.
  scope { User }

  ### Attributes
  # Attributes define the fields that can be set set on a resource on a request
  # and what is provided back to the client in a response.

  # **attribute**<br />
  # Attributes can be defined within a resources definition using the `attribute`
  # method within a resource definition block.
  attribute :first_name, types.String, "The user's first name.", read: true, write: true, hidden: false, required: false do |name, instance, context|
    instance.send(name)
  end

  # Basic attibutes only require a name, a type and a description. By default
  # the resolution of the attribute is invoked by calling a method matching
  # the attributes name on the instance of the resource.
  attribute :last_name, types.String, "The users last name."

  # Sometimes you wish to present information that may not be in the model.
  # For this reason, you can define a block on the attribute which will tell
  # the api how to fetch the value for that attibute. These attributes will
  # default to being readonly attibutes.
  attribute :full_name, types.String, "The user's full name." do |attr_name, instance, context|
    "#{instance.first_name} #{instance.last_name}"
  end

  # Some attributes may be required for certain actions. In this case we
  # can use the required keyword. `true` can be passed to require on all
  # actions, or an action name or array of action names can be passed to
  # target specific actions.
  attribute :email, types.String, "The user's email address.", required: true

  # Some attributes may be write only attributes, these attributes may
  # include information we never want to send back in a response, such as
  # passwords. `false` can be passed to prevent write on all actions, or an
  # action name or array of action names can be passed to whitelist specific
  # actions.
  attribute :password, types.String, "The user's password", required: :create, read: false

  # Some attributes may need to be read only attributes, such as timestamps
  # or other attributes our application controls and should not be set by
  # the end user. `false` can be passed to prevent write on all
  # actions, or an action name or array of action names can be passed to
  # whitelist specific actions.
  attribute :updated_at, types.TimeString, "The last time the user was updated", write: false

  # Some attributes may be tied to "expensive" calls. Rather than optimize
  # your queries to allow for these attributes to be less expensive, we can
  # simply hide the attributes by default. And they can only be used by
  # utlizing [sparce fieldsets](http://jsonapi.org/format/#fetching-sparse-fieldsets).
  # `true` can be passed to hide on all actions, or an action name or array of
  # action names can be passed to target specific actions.
  attribute :friends_count, types.Integer, "The number of friends for a user", write: false, hidden: [:list]

end
