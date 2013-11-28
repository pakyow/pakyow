require "support/helper"

module Pakyow
  module Test
    class StringUtilsTest < Minitest::Test

      def setup
      end

      def teardown
      end

      def test_remove_route_vars
        assert_equal '/', Utils::String.remove_route_vars('/:id'), "Failed to remove route vars"
        assert_equal '/bret', Utils::String.remove_route_vars('/bret'), "Failed to remove route vars"
        assert_equal '/bret', Utils::String.remove_route_vars('/bret/'), "Failed to remove route vars"
        assert_equal '/bret', Utils::String.remove_route_vars('/bret/:id'), "Failed to remove route vars"
        assert_equal 'bret', Utils::String.remove_route_vars(':id0/bret/:id'), "Failed to remove route vars"
        assert_equal 'bret', Utils::String.remove_route_vars(':id0/:id1/bret/:id'), "Failed to remove route vars"
        assert_equal '/bret', Utils::String.remove_route_vars('/bret/:id/:id'), "Failed to remove route vars"
        assert_equal '/fred/barney', Utils::String.remove_route_vars('/fred/:id/barney'), "Failed to remove route vars"
        assert_equal '/fred/barney', Utils::String.remove_route_vars('/fred/:fred_id/barney/:barney_id'), "Failed to remove route vars"
        assert_equal '/fred/barney', Utils::String.remove_route_vars('/fred/:_id/barney/:id'), "Failed to remove route vars"
        assert_equal '/fred/barney', Utils::String.remove_route_vars('/fred/:id/:id2/barney'), "Failed to remove route vars"
        assert_equal '/fred//barney', Utils::String.remove_route_vars('/fred//barney'), "Failed to remove route vars"
      end

      def test_split_at_last_dot
        assert_equal ['one', nil], Utils::String.split_at_last_dot('one'), "Failed to split one"
        assert_equal ['one', ''], Utils::String.split_at_last_dot('one.'), "Failed to split one."
        assert_equal ['', 'one'], Utils::String.split_at_last_dot('.one'), "Failed to split .one"
        assert_equal ['', '/one'], Utils::String.split_at_last_dot('./one'), "Failed to split ./one"
        assert_equal ['one/two.x/three', 'four'], Utils::String.split_at_last_dot('one/two.x/three.four'), "Failed to split one/two.x/three.four"
        assert_equal ['one/two', 'x/three'], Utils::String.split_at_last_dot('one/two.x/three'), "Failed to split one/two.x/three"
        assert_equal ['one.two', 'three'], Utils::String.split_at_last_dot('one.two.three'), "Failed to split one.two.three"
      end

      def test_path_is_accurate_on_windows
        assert_equal(Utils::String.parse_path_from_caller("C:/test/test_application.rb:5"), 'C:/test/test_application.rb')
      end

    end
  end
end
