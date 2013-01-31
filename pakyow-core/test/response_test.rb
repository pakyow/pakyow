require 'support/helper'

class ResponseTest < MiniTest::Unit::TestCase
  def test_extends_rack_response
    assert_same Rack::Response, Pakyow::Response.superclass
  end
end
