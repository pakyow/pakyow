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

  def test_view_index_root
      v = @presenter.view_for_view_path("/index", "approot")
      assert_equal("approot", v.title)
  end

  def test_full_view_index_root
      v = @presenter.view_for_full_view_path("/index/main.html")
      assert_equal("/index/main", v.content)
      v = @presenter.view_for_full_view_path("/index")
      assert_equal("approot", v.title)
      assert_equal("", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("/index",true)
      assert_equal("approot", v.title)
      assert_equal("/index/main", v.find('#main').content[0])

      # a
      v = @presenter.view_for_full_view_path("/a/b",true)
      assert_equal("v1", v.title)
      assert_equal("a/b/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("/a/b")
      assert_equal("v1", v.title)
      assert_equal("", v.find('#main').content[0])

      v = @presenter.view_for_full_view_path("/a/b/index",true)
      assert_equal("v1", v.title)
      assert_equal("a/b/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("/a/b/index")
      assert_equal("v1", v.title)
      assert_equal("", v.find('#main').content[0])

      v = @presenter.view_for_full_view_path("a/b/b",true)
      assert_equal("a", v.title)
      assert_equal("a/b/b/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("a/b/b",false)
      assert_equal("a", v.title)
      assert_equal("", v.find('#main').content[0])

      # aa
      v = @presenter.view_for_full_view_path("/aa/b",true)
      assert_equal("v1", v.title)
      assert_equal("aa/b.a/index.v1/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("/aa/b")
      assert_equal("v1", v.title)
      assert_equal("", v.find('#main').content[0])

      v = @presenter.view_for_full_view_path("/aa/b/index",true)
      assert_equal("v1", v.title)
      assert_equal("aa/b.a/index.v1/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("/aa/b/index")
      assert_equal("v1", v.title)
      assert_equal("", v.find('#main').content[0])

      v = @presenter.view_for_full_view_path("aa/b/b",true)
      assert_equal("a", v.title)
      assert_equal("aa/b/b/main", v.find('#main').content[0])
      v = @presenter.view_for_full_view_path("aa/b/b",false)
      assert_equal("a", v.title)
      assert_equal("", v.find('#main').content[0])
  end

end