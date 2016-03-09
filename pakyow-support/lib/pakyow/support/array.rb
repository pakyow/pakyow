class Array
  def self.ensure(object)
    if object.respond_to?(:to_ary)
      object.to_ary
    else
      [object]
    end
  end
end
