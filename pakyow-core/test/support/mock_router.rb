class MockRouter
  attr_reader :rerouted, :handled

  def reroute(*args)
    @rerouted = true
  end

  def handle(*args)
    @handled = true
  end
end
