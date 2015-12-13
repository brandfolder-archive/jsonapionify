require 'erb'
require 'redcarpet'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array'

module JSONAPIonify
  class Documentation
    using JSONAPIonify::IndentedString
    RENDERER = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

    def self.render_markdown(string)
      RENDERER.render(string.deindent)
    end

    attr_reader :api

    def initialize(api, template: nil)
      template ||= File.join(__dir__, 'documentation/template.erb')
      @api     = api
      @erb     = ERB.new File.read(template)
    end

    def result
      @erb.result(binding)
    end

  end
end
