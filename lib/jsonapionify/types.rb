require 'oj'

module JSONAPIonify::Types
  extend JSONAPIonify::Autoload
  autoload_all

  DumpError    = Class.new(StandardError)
  LoadError    = Class.new(StandardError)
  NotNullError = Class.new(StandardError)

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

    def self.dumper(&block)
      meth = instance_method define_method(:dump, &block)
      define_method(:dump) do |value|
        return nil if value.nil? && !not_null?
        raise NotNullError if value.nil? && not_null?
        meth.bind(self).call(value)
      end
    end

    def self.loader(&block)
      meth = instance_method define_method(:load, &block)
      define_method(:load) do |value|
        return nil if value.nil? && !not_null?
        raise NotNullError if value.nil? && not_null?
        meth.bind(self).call(value)
      end
    end

    loader do |value|
      value
    end

    dumper do |value|
      JSON.load JSON.dump value
    end

    def name
      self.class.name.split('::').last.chomp('Type')
    end

    attr_reader :options

    def initialize(**options)
      run_callbacks :initialize do
        @options = options
      end
    end

    def to_s
      name = self.class.name.split('::').last.chomp('Type')
      name << "[#{options[:of].to_s}]" if options[:of]
      name
    end

    def not_null!
      @not_null = true
      self
    end

    def not_null?
      !!@not_null
    end

    private

    def verify(non_ruby)
      dump(load(non_ruby)) == non_ruby
    end

  end
end
