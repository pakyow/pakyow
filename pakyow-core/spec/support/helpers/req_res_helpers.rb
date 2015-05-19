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
