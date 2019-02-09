RSpec.shared_examples :log_formatter do
  let :severity do
    "DEBUG"
  end

  let :datetime do
    Time.now
  end

  let :progname do
    :rspec
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, HTTP::Protocol::Headers.new([])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :error do
    begin
      raise ArgumentError, "foo"
    rescue => error
    end

    error
  end

  let :level do
    4
  end

  let :logger_id do
    "123"
  end

  let :logger_type do
    :test
  end

  let :logger_elapsed do
    0.00042
  end

  before do
    allow(Pakyow).to receive(:global_logger).and_return(double(:global_logger, level: level))
  end

  def event(message)
    event = double(:event, level: level, data: {
      logger: double(:logger, id: logger_id, type: logger_type, elapsed: logger_elapsed), message: message
    })
  end
end
