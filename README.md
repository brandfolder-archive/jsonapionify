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

### Context: Read First

Before we get started with defining an API, you should understand a pattern used heavily throughout JSONAPIonify. This pattern is called a context. A context is a definition of data that is memoized and passed around a request. You may see context used as follows:

```ruby
before :create do |context|
  puts context.request.request_method
end
```

Contexts can also call other contexts within their definitions:

```ruby
context :request_method do |context|
  context.request.request_method
end
```

JSONApionify already ships with a set of predefined contexts.

### Create an API

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

### Predefined Contexts

#### request_body [readonly]
The raw body of the request

#### request_object [readonly]
The JSON parsed into a JSONApionify Structure Object. Keys can be accessed as symbols.

#### id [readonly]
The id present in the request path, if present.

#### request_id [readonly]
The id of the requested resource, within the data attribute of the request object.

#### request_attributes [readonly]
The parsed attributes from the request object. Accessing this context, will also validate the data/structure.

#### request_relationships [readonly]
The parsed relationships from the request object. Accessing this context, will also validate the data/structure.

#### request_instance [readonly]
The instance of the object found from the request's data/type and data/id attibutes. This is determined from the resource's defined scope.

#### request_resource [readonly]
The resource's scope determined from the request's data/type attribute.

#### request_data [readonly]
The data attribute in the top level object of the request

#### authentication [readonly]
An object containing the authentication data.

#### links
The links object that will be present in the response.

#### meta
The meta object that will be present in the response.

#### response_object
The jsonapi object that will be used for the response.

#### response_collection
The response for the collection.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brandfolder/jsonapionify. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
