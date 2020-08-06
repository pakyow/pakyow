controller :root do
  def self.context
    :common
  end

  def self.common?
    true
  end
end
