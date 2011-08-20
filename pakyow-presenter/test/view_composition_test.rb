require "test/helper"

class ViewCompositionTest < Test::Unit::TestCase

  def setup
    Configuration::Base.presenter.view_dir = "test/views"
    @presenter = Pakyow::Presenter::Presenter.new
    @presenter.reload!
  end

  def teardown
    # Do nothing
  end

  def test_view_index
    v = @presenter.view_for_view_path("/index", "pakyow")
    assert_equal("YOU SHOULD NEVER SEE THIS", v.find("#main").first.content)
  end

  def test_view_index_deep
    v = @presenter.view_for_view_path("/index", "pakyow", true)
    assert_equal("/index/main", v.find("#main").first.content)
  end

  def test_view_r11
    v = @presenter.view_for_view_path("/r1/r11", "another", true)
    assert_equal("r11 foot", v.find("#foot").first.content)
  end

  def test_view_abb
    v = @presenter.view_for_view_path("/a/b/b", "a", true)
    assert_equal("a/b/b/main", v.find('#main').first.content)
  end

  def test_view_ab
    v = @presenter.view_for_view_path("/a/b", "a", true)
    assert_equal("a/b/main", v.find('#main').first.content)
  end

  def test_view_a
    v = @presenter.view_for_view_path("/a", "main", true)
    assert(v.content.start_with?('root main'))
  end

end