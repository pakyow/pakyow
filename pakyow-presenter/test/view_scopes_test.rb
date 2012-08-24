require 'helper'

class ViewScopesTest < Test::Unit::TestCase

  def setup
    @view = create_view_from_string(<<-D)
    <div data-scope="post">
      <div data-scope="comment"></div>
      <div data-scope="comment"></div>
    </div>
    D
  end

  def teardown
    # Do nothing
  end

  def test_single_scope_found
    assert_equal @view.scope(:post).length, 1
    assert_equal @view.scope('post').length, 1
  end

  def test_multiple_scopes_found
    assert_equal @view.scope(:comment).length, 2
  end

  def test_nested_scopes_found
    assert_equal @view.scope(:post).scope(:comment).length, 2
  end

  def test_invalid_scopes_not_found
    assert_nil @view.scope(:fail)
  end

  private

  def create_view_from_string(string)
    View.new(Nokogiri::HTML.fragment(string))
  end

end
