require 'pry'
require 'active_support/callbacks'

class Test
  include ActiveSupport::Callbacks

  define_callbacks :runnit

  set_callback :runnit, :before do
    binding.pry
  end

  def runnit
    key = 'a'
    run_callbacks :runnit do
      puts "RUN!"
    end
  end

end

Test.new.runnit