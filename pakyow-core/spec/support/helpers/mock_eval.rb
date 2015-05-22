class MockEval
  def initialize
    @calls = []
  end

  def method_missing(name, *args)
    @calls << name
  end

  def called?(m)
    @calls.include?(m)
  end
end
