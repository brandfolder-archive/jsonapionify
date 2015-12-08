require 'erb'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array'

module JSONAPIonify
  class Documentation

    attr_reader :api

    def initialize(api, template: nil)
      template ||= File.join(__dir__, 'documentation/template.erb')
      @api = api
      @erb = ERB.new File.read(template)
    end

    def result
      @erb.result(binding)
    end

  end
end