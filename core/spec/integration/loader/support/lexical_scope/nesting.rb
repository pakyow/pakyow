state :foo do
  def self.nesting
    Module.nesting
  end
end
