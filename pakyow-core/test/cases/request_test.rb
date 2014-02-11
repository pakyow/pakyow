require 'support/helper'

module Pakyow
  module Test
    class RequestTest < Minitest::Test
      include ReqResHelpers

      def setup
        @request = mock_request('/foo/', :get, { 'HTTP_REFERER' => '/bar/' })
      end

      def test_extends_rack_request
        assert_same Rack::Request, Pakyow::Request.superclass
      end

      def test_path_calls_path_info
        assert_equal @request.path, @request.path_info
      end

      def test_method_is_proper_format
        assert_equal :get, @request.method
      end

      def test_url_is_split
        assert_equal 1, @request.path_parts.length
        assert_equal 'foo', @request.path_parts[0]
      end

      def test_referer_is_split
        assert_equal 1, @request.referer_parts.length
        assert_equal 'bar', @request.referer_parts[0]
      end
    end
  end
end
