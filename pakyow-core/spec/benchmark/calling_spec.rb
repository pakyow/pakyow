require "rspec-benchmark"
require "async/http/request"
require "http/protocol/headers"

# cases to benchmark:
#
# - normalization
# - request parsing
# - disabled logger
#   - also don't log prologue/epilogue

RSpec.describe "environment call performance", benchmark: true do
  include RSpec::Benchmark::Matchers

  before do
    Pakyow.config.logger.destinations = [] #[File.open(File::NULL, "w")]
    require "pakyow/logger/formatters/logfmt"
    Pakyow.config.logger.formatter = Pakyow::Logger::Formatters::Logfmt
    Pakyow.setup.to_app
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, HTTP::Protocol::Headers.new([["content-type", "text/html"]])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("localhost", "http")
    end
  end

  context "no mounted apps" do
    it "performs" do
      expect {
        Pakyow.call(request)
      }.to perform_at_least(100_000, time: 5.0, warmup: 1.0).ips
    end
  end
end
