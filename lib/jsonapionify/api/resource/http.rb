module JSONAPIonify::Api
  class Resource::Http < Resource

    Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
      define_action(symbol).response status: code do
        error_now symbol
      end
    end

  end
end