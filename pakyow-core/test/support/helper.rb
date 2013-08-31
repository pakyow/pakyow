require 'rubygems'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'pp'

require 'pakyow-core'

require 'support/app'
require 'support/mock_router'
# require 'test_handler'
# require 'test_model'
# require 'test_presenter'
# require 'test_controller'
# require 'string_utils_test'
# require 'route_block_evaluator'

def mock_request(path = '/foo/')
  r = Pakyow::Request.new({ "PATH_INFO" => path, "REQUEST_METHOD" => 'GET', "HTTP_REFERER" => '/bar/', "rack.input" => {} })
  r.path = path
  r.method = :get
  r.app = Pakyow.app
  r.setup
  r
end

def mock_response
  Pakyow::Response.new
end
