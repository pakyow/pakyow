require 'helper'

class RequestTest < Test::Unit::TestCase
  def test_extends_rack_request
    assert_same(Rack::Request, Pakyow::Request.superclass)
  end
  
  def test_path_calls_path_info
    assert_equal(request.path, request.path_info)
  end
  
  def test_method_is_proper_format
    assert_equal(:get, request.method)
  end
  
  def test_url_is_split
    assert_equal(1, request.path_parts.length)
    assert_equal('foo', request.path_parts[0])
  end
  
  def test_referer_is_split
    assert_equal(1, request.referer_parts.length)
    assert_equal('bar', request.referer_parts[0])
  end
  
  private
  
  def request
    Pakyow::Request.new({ "PATH_INFO" => '/foo/', "REQUEST_METHOD" => 'GET', "HTTP_REFERER" => '/bar/', "rack.input" => {} })
  end
end
