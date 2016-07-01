# JSONAPIonify
[![Gem Version](https://badge.fury.io/rb/jsonapionify.svg)](https://badge.fury.io/rb/jsonapionify)
[![Build Status](https://travis-ci.org/brandfolder/jsonapionify.svg?branch=master)](https://travis-ci.org/brandfolder/jsonapionify)
[![Code Climate](https://codeclimate.com/repos/5672446f137f95309c0067c6/badges/a369f0a182ce111c8fcd/gpa.svg)](https://codeclimate.com/repos/5672446f137f95309c0067c6/feed)
[![Test Coverage](https://codeclimate.com/repos/5672446f137f95309c0067c6/badges/a369f0a182ce111c8fcd/coverage.svg)](https://codeclimate.com/repos/5672446f137f95309c0067c6/coverage)

JSONAPIonify is a framework for building JSONApi 1.0 compliant
APIs. It can run as a standalone rack app or as part of a larger framework such
as rails. In addition, it auto-generates beautiful documentation.

Live Example:

* [Resource](https://api.brandfolder.com/v2/slug/brandfolder)
* [Documentation](https://api.brandfolder.com/v2/docs) (screenshot below)

  [![Documentation Example](https://api.url2png.com/v6/P3CAE278FC306AA/50ef2ba09c77f6fb25dd7f179de2a704/png/?thumbnail_max_width=500&url=https%3A%2F%2Fapi.brandfolder.com%2Fv2%2Fdocs)](https://api.brandfolder.com/v2/docs)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapionify'
```

And then execute:

    $ bundle

## Usage

Below is a high level overview of all the available methods. For for detail see
the yard documentation and the [examples](examples).

### APIs

Api Definitions are the basis of JSONApi's DSL. They encompass resources that are available and can be run as standalone rack apps or be mounted within a rails app.

```
class MyCompanyApi < JSONAPIonify::Base

  # Write a description for your API.
  description <<~markdown
  A description of your API, that will be available at the top of the documentation.
  markdown

  # Add some rack middleware
  use Rack::SSL::Enforcer

  # Handle Authorization

end
```

### Resources

Resources are what the API serves. They usually link to models. Resources are defined by calling `.define_resource` on the class of a defined api.

```ruby
MyCompanyApi.define_resource :users do
  # ... The resource definition
end
```

#### Scope
Each api uses a scope to determine how to look up objects the serve the request. By default the resource will look for a class that is similar to it's scope.

```ruby
MyCompanyApi.define_resource :users do
  scope { Person }
end
```

#### ID Attribute
JSONAPI needs an attribute to represent the object's id. This defaults to the `id` method, but can be overridden.

```ruby
MyCompanyApi.define_resource :users do
  id :key
end
```

#### Instance Lookup
In order to locate an instance in the defined scope, the resource needs a instructions to do so. If the scope is a descendant of `ActiveRecord::Base`, it will automatically use `scope.find(id)` for the lookup.

```ruby
MyCompanyApi.define_resource :users do
  instance { |scope, id| scope.find_by key: id }
end
```

#### Instance Builder
When creating an instance, the resource needs to know how to build a new object. If the scope is a descendant of `ActiveRecord::Base`, it will automatically use `scope.new` to build the object.

#### Contexts
Contexts are memoized blocks of code that are used throughout the request lifecycle of a resource. They can be referenced in [`hooks`](#hooks), [`actions`](#hooks), [`attributes`](#attributes), other [`contexts`](#contexts), etc. A context is defined as follows:

```ruby
MyCompanyApi.define_resource :users do
  context :request_method do |context|
    context.request.request_method
  end
end
```

> **NOTE:** The gem ships with [predefined contexts](#predefined-contexts).

#### Attributes
Attributes define what fields will appear in the response. Attribute definitions require a name, a type, and a description. In addition, the attribute may include a block that defines how the value is resolved.

```ruby
MyCompanyApi.define_resource :users do
  attribute :name, types.String, 'the users name' do |attr_name, instance, context| do
    instance.public_send(attr_name)
  end
end
```

##### Attribute types
Attributes require a type that map to JSON types. They are as follows:  
`types.String`, `types.Boolean`, `types.Integer`, `types.Float`, `types.Array(of: ?)`, `types.Object`

> Array types take an `of` keyword of another type.

#### Relationships
Relationships define the way resources reference each other. There are two types of relationships. Relationships behave just like the resource they represent except it's scoped to the parent object. By default the scope of of a relationship resolves to a method equal to the name of the relationship. This can be overridden by passing a `Proc` to the resolve keyword. In addition, the default resource the object resolves to can be specified with the `resource` keyword. If a relationship is given a block it is treated the same as a resource definition, but it's [actions](#actions) are limited by the type of the relationship.

##### One-to-One
One-to-One relationships allow a parent resource to reference a single instance of another resource. It is defined as follows:

```ruby
MyCompanyApi.define_resource :users do
  relates_to_one :thing, resolve: proc { |rel, instance, context| instance.public_send(rel) } do
    replace
  end
end
```

##### One-to-Many
One-to-One relationships allow a parent resource to reference a collection of another resource. It is defined as follows:

```ruby
MyCompanyApi.define_resource :users do
  relates_to_many :friends, resource: :users, resolve: proc { |rel, instance, context| instance.public_send(rel) } do
    add
    replace
    remove
  end
end
```

#### Actions
Actions define the routes of a resource and what processing happens when that route is called.

**Root level resources have the following actions:**

| Action | Path
|--------|-----
| List   | `GET /{resource}`
| Create | `POST /{resource}`
| Read   | `GET /{resource}/{id}`
| Update | `PATCH /{resource}/{id}`
| Delete | `DELETE /{resource}/{id}`

**One-to-Many relationships resources have the following actions:**

| Action | Path
|--------|-----
| List   | `GET /{resource}/{id}/{relationship}`
| Create | `POST /{resource}/{id}/{relationship}`
| Show   | `GET /{resource}/{id}/relationships/{relationship}`
| Add    | `POST /{resource}/{id}/relationships/{relationship}`
| Remove | `DELETE /{resource}/{id}/relationships/{relationship}`
| Replace| `PATCH /{resource}/{id}/relationships/{relationship}`

**One-to-One relationships resources have the following actions:**

| Action | Path
|--------|-----
| Read   | `GET /{resource}/{id}/{relationship}`
| Show   | `GET /{resource}/{id}/relationships/{relationship}`
| Replace| `PATCH /{resource}/{id}/relationships/{relationship}`

#### Hooks
Hooks can be invoked throughout the request lifecycle. They are defined in the following order:

```
before_request
  before_{action}
    before_commit_{action}
      [commit action]
    after_commit_{action}
    before_response
      [response]
    after_response
  after_{action}
after_request
```

A hook can be defined on a resource with:

```ruby
MyCompanyApi.define_resource :users do
  before :create do |context|
    puts context.request.request_method
  end
end
```

### Predefined Contexts

| Context                 | Description
|---------                |----------
| `request`               | The request.  
| `request_body`          | The raw body of the request.
| `request_object`        | The JSON parsed into a JSONApionify Structure Object. Keys can be accessed as symbols.
| `id`                    | The id present in the request path, if present.
| `request_id`            | The id of the requested resource, within the data attribute of the request object.
| `request_attributes`    | The parsed attributes from the request object. Accessing this context, will also validate the data/structure.
| `request_relationships` | The parsed relationships from the request object. Accessing this context, will also validate the data/structure.
| `request_instance`      | The instance of the object found from the request's data/type and data/id attributes. This is determined from the resource's defined scope.
| `request_resource`      | The resource's scope determined from the request's data/type attribute.
| `request_data`          | The data attribute in the top level object of the request
| `authentication`        | An object containing the authentication data.
| `links`                 | The links object that will be present in the response.
| `meta`                  | The meta object that will be present in the response.
| `response_object`       | The jsonapi object that will be used for the response.
| `response_collection`   | The response for the collection.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brandfolder/jsonapionify. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
