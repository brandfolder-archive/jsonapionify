class JSONAPIonify::Structure::Helpers::MetaDelegate
  attr_reader :object

  def initialize(object)
    @object = object
  end

  def []=(k, v)
    object[:meta]    ||= {}
    object[:meta][k] = v
  end

  def [](k)
    object[:meta] && object[:meta][k]
  end
end
