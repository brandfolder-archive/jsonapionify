module JSONAPIonify::Api
  module Resource::Defaults
    extend JSONAPIonify::Autoload
    autoload_all

    def self.included(klass)
      constants(false).each { |const| klass.include const_get const, false }
    end
  end
end
