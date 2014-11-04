require_relative 'support/helper'

class PresenterHelpersTest < Minitest::Test
  def setup
    @context = MockPresenterContext.new
  end

  def test_delegates_to_presenter
    %w[store store= content view= partial template template= page page= path path= compose].each do |delegated|
      delegated = delegated.to_sym
      @context.send(delegated)
      assert @context.presenter.called?(delegated)
    end
  end

  def test_view_returns_view_context
    assert @context.view.is_a?(ViewContext)
  end

  def test_partial_returns_view_context
    assert @context.partial(:foo).is_a?(ViewContext)
  end

  def test_template_returns_view_context
    assert @context.template.is_a?(ViewContext)
  end

  def test_page_returns_view_context
    assert @context.page.is_a?(ViewContext)
  end

  def test_container_returns_view_context
    assert @context.container(:foo).is_a?(ViewContext)
  end
end

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

class MockPresenterContext
  include Pakyow::AppHelpers
  attr_reader :presenter, :context

  def initialize
    @presenter = MockPresenter.new
    @context = AppContext.new
  end
end
