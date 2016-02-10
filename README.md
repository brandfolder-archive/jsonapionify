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

  [![Documentation Example](https://api.url2png.com/v6/P3CAE278FC306AA/50ef2ba09c77f6fb25dd7f179de2a704/png/?thumbnail_max_width=500&url=https%3A%2F%2Fapi.brandfolder.com%2Fv2%2Fdocs)]((https://api.brandfolder.com/v2/docs))

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapionify'
```

And then execute:

    $ bundle

## Usage

Refer to the [wiki](https://github.com/brandfolder/jsonapionify/wiki) for detailed
information on how to use the framework.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/brandfolder/jsonapionify. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
