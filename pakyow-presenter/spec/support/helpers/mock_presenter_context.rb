class MockPresenterContext
  include Pakyow::AppHelpers
  attr_reader :presenter, :context

  def initialize
    @presenter = MockPresenter.new
    @context = Pakyow::AppContext.new
  end
end
