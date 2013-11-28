require 'support/helper'

module Pakyow
  module Test
    class ResponseTest < Minitest::Test
      def test_extends_rack_response
        assert_same Rack::Response, Pakyow::Response.superclass
      end
    end
  end
end
