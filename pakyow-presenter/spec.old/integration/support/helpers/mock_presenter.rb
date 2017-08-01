class MockPresenter
  def initialize
    @calls = []
  end

  def method_missing(method, *args)
    @calls << method
  end

  def called?(method)
    @calls.include?(method)
  end
end
