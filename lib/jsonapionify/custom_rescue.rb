require 'unstrict_proc'

class JSONAPIonify::CustomRescue
  using UnstrictProc

  def self.perform(**opts, &block)
    new(**opts, &block).perform
  end

  def initialize(remove: [], source: nil, formatter:, &block)
    @block = block
    @formatter = formatter
    @source = source || block
    @locs = Array.wrap remove
    f, l = self.class.method(:perform).source_location
    @locs << [f, l+1].join(':')
  end

  def source_location
    source.source_location
  end

  def perform
    @block.call
  rescue => e
    loc = [__FILE__, __LINE__-2].join(':')
    formatted_value = @formatter.unstrict.call(Error.new(e, @source))
    index = e.backtrace.index { |l| l.include? loc }
    e.backtrace[index] = formatted_value if index && formatted_value
    e.backtrace.delete_if { |l| @locs.any? { |rl| l.include? rl } }
    raise e
  end

  class Error < Struct.new :error, :source
    delegate :source_location, to: :source
  end

end
