require 'support/helper'

class PresenterViewTest < MiniTest::Unit::TestCase

  def setup
    TestApplication.stage(:test)
    Pakyow.app.presenter.view_store = :test
  end

  def teardown
    # Do nothing
  end

  def test_view_index
    v = View.new("/index/main.html")
    assert_equal("/index/main", v.content)
  end

  def test_view_index_root
    v = View.at_path("/index")
    assert_equal("approot", v.title)
  end

  def test_full_view_index_root
    v = View.new("/index/main.html")
    assert_equal("/index/main", v.content)
    v = View.at_path("/index")
    assert_equal("approot", v.title)
    assert_equal("/index/main", v.container(:main).content[0])

    # a
    v = View.at_path("/a/b")
    assert_equal("v1", v.title)
    assert_equal("a/b/main", v.container(:main).content[0])

    v = View.at_path("/a/b/index")
    assert_equal("v1", v.title)
    assert_equal("a/b/main", v.container(:main).content[0])

    v = View.at_path("a/b/b")
    assert_equal("a", v.title)
    assert_equal("a/b/b/main", v.container(:main).content[0])

    # aa
    v = View.at_path("/aa/b")
    assert_equal("v1", v.title)
    assert_equal("aa/b.a/index.v1/main", v.container(:main).content[0])

    v = View.at_path("/aa/b/index")
    assert_equal("v1", v.title)
    assert_equal("aa/b.a/index.v1/main", v.container(:main).content[0])

    v = View.at_path("aa/b/b")
    assert_equal("a", v.title)
    assert_equal("aa/b/b/main", v.container(:main).content[0])
  end

end