module JSONAPIonify::Api
  module Resource::Definitions
    extend JSONAPIonify::Autoload
    autoload_all

    def self.extended(klass)
      klass.extend Contexts
      klass.extend Hooks
      constants(false).each do |const|
        mod = const_get(const, false)
        klass.extend mod unless klass.singleton_class < mod
      end
    end
  end
end
