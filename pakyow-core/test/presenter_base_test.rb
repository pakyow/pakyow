require 'support/helper'

class PresenterBaseTest < MiniTest::Unit::TestCase
  def test_presenter_set_when_inherited
    load 'support/presenter.rb'
    assert_equal TestPresenter, Configuration::Base.app.presenter
  end

  def test_presenter_is_singleton
    load 'support/presenter.rb'
    assert_same TestPresenter.instance, TestPresenter.instance
  end
end
