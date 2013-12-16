require_relative 'support/helper'

class PresenterHelpersTest < Minitest::Test
  def setup
    @context = MockPresenterContext.new
  end

  def test_delegates_to_presenter
    %w[store store= content view view= partial template template= page page= path path= compose].each do |delegated|
      delegated = delegated.to_sym
      @context.send(delegated)
      assert @context.presenter.called?(delegated)
    end
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
  attr_reader :presenter

  def initialize
    @presenter = MockPresenter.new
  end
end
