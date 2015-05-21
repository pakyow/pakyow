require 'rubygems'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'pp'
require 'pry'

require File.join(File.dirname(__FILE__), '../../../pakyow-support/lib/pakyow-support')
require File.join(File.dirname(__FILE__), '../../lib/pakyow-core')

require_relative 'app'
require_relative 'mock_router'
# require 'test_handler'
# require 'test_model'
# require 'test_presenter'
# require 'test_controller'
# require 'string_utils_test'
# require 'route_block_evaluator'

module ReqResHelpers
  def mock_request(path = '/', method = :get, headers = {})
    opts = {
      "PATH_INFO" => path,
      "REQUEST_METHOD" => method.to_s.upcase,
      "rack.input" => StringIO.new,
    }.merge(headers)

    Pakyow::Request.new(opts)

    # r = Pakyow::Request.new({ "PATH_INFO" => path, "REQUEST_METHOD" => 'GET', "HTTP_REFERER" => '/bar/', "rack.input" => {} })
    # r.path = path
    # r.method = :get
    # r.app = Pakyow.app
    # r.setup
    # r
  end

  def mock_response
    Pakyow::Response.new
  end
end
