require 'support/helper'

class PresenterViewTest < Minitest::Test

  def setup
    @view_store = :test
    Pakyow::App.stage(:test)
    Pakyow.app.presenter.view_store = @view_store
  end

  def teardown
    # Do nothing
  end

  def test_view_index
    v = View.new("/index/main.html", @view_store)
    assert_equal("/index/main", v.html)
  end

  def test_view_index_root
    v = View.at_path("/index", @view_store)
    assert_equal("approot", v.title)
  end

  def test_full_view_index_root
    v = View.new("/index/main.html", @view_store)
    assert_equal("/index/main", v.html)
    v = View.at_path("/index", @view_store)
    assert_equal("approot", v.title)
    assert_equal("/index/main", v.container(:main).html[0])

    # a
    v = View.at_path("/a/b", @view_store)
    assert_equal("v1", v.title)
    assert_equal("a/b/main", v.container(:main).html[0])

    v = View.at_path("/a/b/index", @view_store)
    assert_equal("v1", v.title)
    assert_equal("a/b/main", v.container(:main).html[0])

    v = View.at_path("a/b/b", @view_store)
    assert_equal("a", v.title)
    assert_equal("a/b/b/main", v.container(:main).html[0])

    # aa
    v = View.at_path("/aa/b", @view_store)
    assert_equal("v1", v.title)
    assert_equal("aa/b.a/index.v1/main", v.container(:main).html[0])

    v = View.at_path("/aa/b/index", @view_store)
    assert_equal("v1", v.title)
    assert_equal("aa/b.a/index.v1/main", v.container(:main).html[0])

    v = View.at_path("aa/b/b", @view_store)
    assert_equal("a", v.title)
    assert_equal("aa/b/b/main", v.container(:main).html[0])
  end

end