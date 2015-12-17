module JSONAPIonify::Api
  class ParamOptions

    def self.hash_to_keypaths(hash)
      mapper = lambda do |hash, ary|
        hash.each_with_object(ary) do |(k, v), a|
          a << (map = [k.to_sym])
          mapper[v, map] if v.is_a?(Hash)
        end
      end
      mapper[hash, []].map(&:flatten)
    end

    def self.keypath_to_string(*paths)
      first_path, *rest = paths
      "#{first_path}#{rest.map { |path| "[#{path}]" }.join}"
    end

    def self.invalid_parameters(hash, keypaths)
      invalid_key_paths = hash_to_keypaths(hash) - keypaths
      invalid_key_paths.map do |paths|
        keypath_to_string(*paths)
      end
    end

    def self.missing_parameters(hash, keypaths)
      missing_key_paths = keypaths - hash_to_keypaths(hash)
      missing_key_paths.map do |paths|
        keypath_to_string(*paths)
      end
    end

    attr_reader :keypath, :actions, :required

    def initialize(*keys, actions: nil, required: false)
      @keypath  = keys
      @actions  = Array.wrap(actions)
      @required = required
    end

    def string
      self.class.keypath_to_string(*@keypath)
    end

  end
end
