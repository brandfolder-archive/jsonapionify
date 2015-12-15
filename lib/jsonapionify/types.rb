require 'oj'

module JSONAPIonify::Types
  extend JSONAPIonify::Autoload
  autoload_all

  def types
    DefinitionFinder
  end

  module DefinitionFinder
    def self.method_missing(m, *args)
      JSONAPIonify::Types.const_get("#{m}Type", false).new(*args)
    rescue NameError
      raise TypeError, "#{m} is not a valid JSON type."
    end
  end

  class BaseType
    include JSONAPIonify::Callbacks
    define_callbacks :initialize

    def name
      self.class.name.split('::').last.chomp('Type')
    end

    attr_reader :options

    def initialize(**options)
      run_callbacks :initialize do
        @options = options
      end
      freeze
    end

    def load(non_ruby)
      non_ruby
    end

    def dump(ruby)
      Oj.load Oj.dump ruby
    end

    def verify(non_ruby)
      dump(load(non_ruby)) == non_ruby
    end

  end
end
