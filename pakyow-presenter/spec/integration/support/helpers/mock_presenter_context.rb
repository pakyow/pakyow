class MockPresenterContext
  include Pakyow::Helpers

  attr_reader :presenter, :context

  def initialize
    @presenter = MockPresenter.new
    @context = Pakyow::AppContext.new
  end
end
