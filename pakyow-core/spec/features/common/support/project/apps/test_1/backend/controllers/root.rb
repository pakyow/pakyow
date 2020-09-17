controller :root do
  if respond_to?(:context)
    singleton_class.remove_method(:context)
  end

  def self.context
    :application
  end
end
