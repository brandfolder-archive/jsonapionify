module JSONAPIonify::Api
  module Relationship::Blocks

    def self.extended(klass)
      klass.class_eval do
        prepend_class
        append_class
      end
    end

    def prepend_class(&block)
      block ||= proc {}
      if method_defined? :class_prepends
        previous_prepends = instance_method(:class_prepends)
        define_method :class_prepends do
          (previous_prepends.bind(self).call + [block]).freeze
        end
      else
        prepends = [block].freeze
        define_method :class_prepends do
          prepends
        end
      end
    end

    def append_class(&block)
      block ||= proc {}
      if method_defined? :class_appends
        previous_appends = instance_method(:class_appends)
        define_method :class_appends do
          (previous_appends.bind(self).call + [block]).freeze
        end
      else
        appends = [block].freeze
        define_method :class_appends do
          appends
        end
      end
    end
  end
end
