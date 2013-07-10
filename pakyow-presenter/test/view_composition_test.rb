require 'support/helper'

class ViewCompositionTest < Minitest::Test

  def setup
    @view_store = :test
    Pakyow::App.stage(:test)
    Pakyow.app.presenter.view_store = @view_store
  end

  def teardown
    # Do nothing
  end

  def test_view_index_deep
    v = View.at_path("/index", @view_store)
    assert_equal("/index/main", v.container(:main).first.html)
  end

  def test_view_r11
    v = View.new("/r1/r11/foot.html", @view_store).compile("/r1/r11", @view_store)
    assert_equal("r11 foot", v.html)
  end

  def test_view_abb
    v = View.at_path("/a/b/b", @view_store)
    assert_equal("a/b/b/main", v.container(:main).first.html)
  end

  def test_view_ab
    v = View.at_path("/a/b", @view_store)
    assert_equal("a/b/main", v.container(:main).first.html)
  end

end