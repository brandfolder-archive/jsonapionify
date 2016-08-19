module JSONAPIonify::Api
  class ParamOptions
    extend JSONAPIonify::Structure::Helpers::MemberNames

    def self.reserved?(value)
      %w{sort include}.include? value
    end

    def self.valid?(value)
      super(value) && value =~ /[^\u0061-\u007A]/
    end

    def self.hash_to_keypaths(hash)
      hash.each_with_object([]) do |(k, v), key_paths|
        pather = lambda do |v, current_path|
          if v.is_a? Hash
            v.each do |k, v|
              pather.call(v, [*current_path, k])
            end
          else
            key_paths << current_path.map(&:to_sym)
          end
        end
        pather.call(v, [k])
      end
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

    attr_reader :keypath, :actions, :required, :sticky

    def initialize(*keys, default: nil, actions: nil, required: false, sticky: false)
      @keypath  = keys
      @sticky   = sticky
      @actions  = Array.wrap(actions)
      @default  = default.to_s
      @required = required
    end

    def with_value(value)
      Hash.new.tap do |hash|
        keypath[0..-2].reduce(hash) do |current_hash, key|
          current_hash[key.to_s] = {}
        end[keypath.last.to_s] = value
      end
    end

    def default
      with_value @default
    end

    def default_value
      @default
    end

    def extract_value(params)
      keypath.reduce(params) do |p, key|
        p[key.to_s]
      end
    end

    def has_default?
      @default.present?
    end

    def default_value?(value)
      @default == value
    end

    def string
      self.class.keypath_to_string(*@keypath)
    end

  end
end
