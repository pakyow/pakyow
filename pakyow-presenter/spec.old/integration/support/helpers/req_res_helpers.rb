module ReqResHelpers
  def mock_request(path = '/', method = :get, headers = {})
    opts = {
      "PATH_INFO" => path,
      "REQUEST_METHOD" => method.to_s.upcase,
      "rack.input" => StringIO.new,
    }.merge(headers)

    Pakyow::Request.new(opts)
  end

  def mock_response
    Pakyow::Response.new
  end
end
