class MockPresenterContext
  include Pakyow::Helpers
  include Pakyow::Helpers::Context

  attr_reader :presenter, :context

  def initialize
    @presenter = MockPresenter.new
    @context = Pakyow::AppContext.new
  end
end
