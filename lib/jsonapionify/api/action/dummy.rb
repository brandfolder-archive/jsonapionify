module JSONAPIonify::Api
  module Action::Dummy
    def dummy(&block)
      new(nil, nil, &block)
    end

    def error(name, &block)
      dummy do
        error_now name, &block
      end
    end
  end
end
