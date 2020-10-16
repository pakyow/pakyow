state :foo do
  using Pakyow::Support::DeepFreeze

  def self.perform(value)
    value.deep_freeze
  end
end
