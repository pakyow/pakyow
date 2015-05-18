class RepeatingTestViewCollection < Pakyow::Presenter::ViewCollection
  attr_reader :calls

  def initialize(*args)
    @calls = []
    super
  end

  def repeat(*args, &block)
    @calls << :repeat
    super
  end

  def repeat_with_index(*args, &block)
    @calls << :repeat_with_index
    super
  end

  def match(*args, &block)
    @calls << :match
    super
    self
  end

  def for(*args, &block)
    @calls << :for
    super
  end

  def for_with_index(*args, &block)
    @calls << :for_with_index
    super
  end

  def bind(*args, &block)
    @calls << :bind
    super
  end
end
