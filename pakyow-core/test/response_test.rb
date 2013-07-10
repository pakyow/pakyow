require 'support/helper'

class ResponseTest < Minitest::Test
  def test_extends_rack_response
    assert_same Rack::Response, Pakyow::Response.superclass
  end
end
