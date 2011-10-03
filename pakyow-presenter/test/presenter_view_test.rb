require 'helper'

class PresenterViewTest < Test::Unit::TestCase

  def setup
    Configuration::Presenter.view_dir = "test/views"
    @presenter = Pakyow::Presenter::Presenter.new
    @presenter.load
  end

  def teardown
    # Do nothing
  end

  def test_view_index
    v = @presenter.view_for_view_path("/index", "main")
    assert_equal("/index/main", v.content)
  end
end