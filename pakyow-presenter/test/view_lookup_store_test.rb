require 'helper'

class ViewLookupStoreTest < Test::Unit::TestCase

  def setup
    @store = ViewLookupStore.new("test/views")
  end

  def teardown
    # Do nothing
  end

  def test_abb
    assert_equal("/approot.html", @store.view_info("/a")[:root_view], "Wrong root view for /a")
    assert_equal("/a/b.a/a.html", @store.view_info("/a/b")[:root_view], "Wrong root view for /a/b")
    assert_equal("/a/b.a/a.html", @store.view_info("/a/b/b")[:root_view], "Wrong root view for /a/b/b")

    assert_equal("/main.html", @store.view_info("/a")[:views]['main'], "Wrong main.html view path for /a")
    assert_equal("/a/b.a/main.html", @store.view_info("/a/b")[:views]['main'], "Wrong main.html view path for /a/b")
    assert_equal("/a/b.a/b/main.html", @store.view_info("/a/b/b")[:views]['main'], "Wrong main.html view path for /a/b/b")
  end

  def test_abstract_to_real_path_lookup
    assert_nil(@store.real_path(""), "Should not find real path for empty abstract path")
    assert_nil(@store.real_path("//"), "Should not find real path for //")

    assert_equal("/", @store.real_path("/"), "Wrong real path for /")

    assert_equal("/approot.html", @store.real_path("/approot.html"), "Wrong real path for /approot.html")
    assert_equal("/approot.html", @store.real_path("approot.html"), "Wrong real path for approot.html")
    assert_equal("/main.html", @store.real_path("/main.html"), "Wrong real path for /main.html")
    assert_equal("/main.html", @store.real_path("main.html"), "Wrong real path for main.html")
    assert_equal("/pakyow.html", @store.real_path("/pakyow.html"), "Wrong real path for /pakyow.html")
    assert_equal("/pakyow.html", @store.real_path("pakyow.html"), "Wrong real path for pakyow.html")
    assert_equal("/sidebar.html", @store.real_path("/sidebar.html"), "Wrong real path for /sidebar.html")
    assert_equal("/sidebar.html", @store.real_path("sidebar.html"), "Wrong real path for sidebar.html")

    assert_equal("/index.approot", @store.real_path("/index"), "Wrong real path for /index")
    assert_equal("/index.approot", @store.real_path("index"), "Wrong real path for index")
    assert_equal("/index.approot", @store.real_path("index/"), "Wrong real path for index/")
    assert_equal("/index.approot", @store.real_path("/index/"), "Wrong real path for /index/")
    assert_equal("/index.approot/main.html", @store.real_path("/index/main.html"), "Wrong real path for /index/main.html")
    assert_equal("/index.approot/main.html", @store.real_path("index/main.html"), "Wrong real path for index/main.html")

    assert_equal("/r1.another", @store.real_path("/r1"), "Wrong real path for /r1")
    assert_equal("/r1.another", @store.real_path("/r1/"), "Wrong real path for /r1/")
    assert_equal("/r1.another", @store.real_path("r1/"), "Wrong real path for r1/")
    assert_equal("/r1.another", @store.real_path("r1"), "Wrong real path for r1")
    assert_equal("/r1.another/another.html", @store.real_path("/r1/another.html"), "Wrong real path for /r1/another.html")
    assert_equal("/r1.another/another.html", @store.real_path("r1/another.html"), "Wrong real path for r1/another.html")

    assert_equal("/r1.another/r11", @store.real_path("/r1/r11"), "Wrong real path for /r1/r11")
    assert_equal("/r1.another/r11", @store.real_path("/r1/r11/"), "Wrong real path for /r1/r11/")
    assert_equal("/r1.another/r11", @store.real_path("r1/r11/"), "Wrong real path for r1/r11/")
    assert_equal("/r1.another/r11", @store.real_path("r1/r11"), "Wrong real path for r1/r11")
    assert_equal("/r1.another/r11/another.html", @store.real_path("/r1/r11/another.html"), "Wrong real path for /r1/r11/another.html")
    assert_equal("/r1.another/r11/another.html", @store.real_path("r1/r11/another.html"), "Wrong real path for r1/r11/another.html")

    assert_equal("/r2", @store.real_path("/r2"), "Wrong real path for /r2")
    assert_equal("/r2", @store.real_path("r2"), "Wrong real path for r2")
    assert_equal("/r2", @store.real_path("r2/"), "Wrong real path for r2/")
    assert_equal("/r2", @store.real_path("/r2/"), "Wrong real path for /r2/")
    assert_equal("/r2/sidebar.html", @store.real_path("/r2/sidebar.html"), "Wrong real path for /r2/sidebar.html")
    assert_equal("/r2/sidebar.html", @store.real_path("r2/sidebar.html"), "Wrong real path for r2/sidebar.html")
  end

  def test_slash
    assert(@store.view_info("/"), "No route for /")
    assert_equal("/approot.html", @store.view_info("/")[:root_view], "Wrong root_view for /")
    
    assert_equal("/index.approot/main.html", @store.view_info("/")[:views]["main"], "Wrong main.html view path for /")
    assert_equal("/sidebar.html", @store.view_info("/")[:views]["sidebar"], "Wrong sidebar.html view path for /")
    assert_equal("/approot.html", @store.view_info("/")[:views]["approot"], "Wrong approot.html view path for /")
  end

  def test_index
    assert(@store.view_info("/index"), "No route for /index")
    assert(@store.view_info("/index/"), "No route for /index/")
    assert(@store.view_info("index"), "No route for index")
    assert(@store.view_info("index/"), "No route for index/")
    assert_equal("/approot.html", @store.view_info("/index")[:root_view], "Wrong root_view for /index")

    assert_equal("/index.approot/main.html", @store.view_info("/index")[:views]["main"], "Wrong main.html view path for /index")
    assert_equal("/sidebar.html", @store.view_info("/index")[:views]["sidebar"], "Wrong sidebar.html view path for /index")
    assert_equal("/approot.html", @store.view_info("/index")[:views]["approot"], "Wrong approot.html view path for /index")
  end

  def test_r1
    assert(@store.view_info("/r1"), "No route for /r1")
    assert(@store.view_info("/r1/"), "No route for /r1/")
    assert(@store.view_info("r1"), "No route for r1")
    assert(@store.view_info("r1/"), "No route for r1/")
    assert(@store.view_info("/r1/index"), "No route for /r1/index")
    assert(@store.view_info("/r1/index/"), "No route for /r1/index/")
    assert(@store.view_info("r1/index"), "No route for r1/index")
    assert(@store.view_info("r1/index/"), "No route for r1/index/")
    assert_equal("/r1.another/another.html", @store.view_info("/r1")[:root_view], "Wrong root_view for /r1")
    assert_equal("/r1.another/another.html", @store.view_info("/r1/index")[:root_view], "Wrong root_view for /r1/index")

    assert_equal("/main.html", @store.view_info("/r1")[:views]["main"], "Wrong main.html view path for /r1")
    assert_equal("/main.html", @store.view_info("/r1/index")[:views]["main"], "Wrong main.html view path for /r1/index")
    assert_equal("/sidebar.html", @store.view_info("/r1")[:views]["sidebar"], "Wrong sidebar.html view path for /r1")
    assert_equal("/sidebar.html", @store.view_info("/r1/index")[:views]["sidebar"], "Wrong sidebar.html view path for /r1/index")
  end

  def test_r1_r11
    # route with overridden root_view not at end of route
    assert(@store.view_info("/r1/r11"), "No route for /r1/r11")
    assert(@store.view_info("/r1/r11/"), "No route for /r1/r11/")
    assert(@store.view_info("r1/r11"), "No route for r1/r11")
    assert(@store.view_info("r1/r11/"), "No route for r1/r11/")
    assert(@store.view_info("/r1/r11/index"), "No route for /r1/r11/index")
    assert(@store.view_info("/r1/r11/index/"), "No route for /r1/r11/index/")
    assert(@store.view_info("r1/r11/index"), "No route for r1/r11/index")
    assert(@store.view_info("r1/r11/index/"), "No route for r1/r11/index/")
    assert_equal("/r1.another/r11/another.html", @store.view_info("/r1/r11")[:root_view], "Wrong root_view for /r1/r11")
    assert_equal("/r1.another/r11/another.html", @store.view_info("/r1/r11/index")[:root_view], "Wrong root_view for /r1/r11/index")

    assert_equal("/main.html", @store.view_info("/r1/r11")[:views]["main"], "Wrong main.html view path for /r1/r11")
    assert_equal("/main.html", @store.view_info("/r1/r11/index")[:views]["main"], "Wrong main.html view path for /r1/r11/index")
    assert_equal("/sidebar.html", @store.view_info("/r1/r11")[:views]["sidebar"], "Wrong sidebar.html view path for /r1/r11")
    assert_equal("/sidebar.html", @store.view_info("/r1/r11/index")[:views]["sidebar"], "Wrong sidebar.html view path for /r1/r11/index")
    assert_equal("/r1.another/r11/another.html", @store.view_info("/r1/r11")[:views]["another"], "Wrong another.html for /r1/r11")
    assert_equal("/r1.another/r11/another.html", @store.view_info("/r1/r11/index")[:views]["another"], "Wrong another.html for /r1/r11/index")
    assert_equal("/approot.html", @store.view_info("/r1/r11")[:views]["approot"], "Wrong approot.html for /r1/r11")
    assert_equal("/approot.html", @store.view_info("/r1/r11/index")[:views]["approot"], "Wrong approot.html for /r1/r11/index")
  end

  def test_r2
    assert(@store.view_info("/r2"), "No route for /r2")
    assert(@store.view_info("/r2/"), "No route for /r2/")
    assert(@store.view_info("r2"), "No route for r2")
    assert(@store.view_info("r2/"), "No route for r2/")
    assert(@store.view_info("/r2/index"), "No route for /r2/index")
    assert(@store.view_info("/r2/index/"), "No route for /r2/index/")
    assert(@store.view_info("r2/index"), "No route for r2/index")
    assert(@store.view_info("r2/index/"), "No route for r2/index/")
    assert_equal("/approot.html", @store.view_info("/r2")[:root_view], "Wrong root_view for /r2")
    assert_equal("/approot.html", @store.view_info("/r2/index")[:root_view], "Wrong root_view for /r2/index")

    assert_equal("/main.html", @store.view_info("/r2")[:views]["main"], "Wrong main.html view path for /r2")
    assert_equal("/main.html", @store.view_info("/r2/index")[:views]["main"], "Wrong main.html view path for /r2/index")
    assert_equal("/r2/sidebar.html", @store.view_info("/r2")[:views]["sidebar"], "Wrong sidebar.html view path for /r2")
    assert_equal("/r2/sidebar.html", @store.view_info("/r2/index")[:views]["sidebar"], "Wrong sidebar.html view path for /r2/index")
  end

end