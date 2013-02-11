require 'support/helper'

class ViewCompositionTest < MiniTest::Unit::TestCase

  def setup
    TestApplication.stage(:test)
    Pakyow.app.presenter.view_store = :test
  end

  def teardown
    # Do nothing
  end

  def test_view_index_deep
    v = View.at_path("/index")
    assert_equal("/index/main", v.container(:main).first.content)
  end

  def test_view_r11
    v = View.new("/r1/r11/foot.html").compile("/r1/r11")
    assert_equal("r11 foot", v.content)
  end

  def test_view_abb
    v = View.at_path("/a/b/b")
    assert_equal("a/b/b/main", v.container(:main).first.content)
  end

  def test_view_ab
    v = View.at_path("/a/b")
    assert_equal("a/b/main", v.container(:main).first.content)
  end

end