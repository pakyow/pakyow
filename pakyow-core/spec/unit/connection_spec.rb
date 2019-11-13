require_relative "./connection/shared_examples/authority"
require_relative "./connection/shared_examples/body"
require_relative "./connection/shared_examples/close"
require_relative "./connection/shared_examples/cookies"
require_relative "./connection/shared_examples/endpoint"
require_relative "./connection/shared_examples/format"
require_relative "./connection/shared_examples/fullpath"
require_relative "./connection/shared_examples/headers"
require_relative "./connection/shared_examples/host"
require_relative "./connection/shared_examples/input"
require_relative "./connection/shared_examples/ip"
require_relative "./connection/shared_examples/method"
require_relative "./connection/shared_examples/params"
require_relative "./connection/shared_examples/path"
require_relative "./connection/shared_examples/port"
require_relative "./connection/shared_examples/query"
require_relative "./connection/shared_examples/request"
require_relative "./connection/shared_examples/scheme"
require_relative "./connection/shared_examples/secure"
require_relative "./connection/shared_examples/sleep"
require_relative "./connection/shared_examples/status"
require_relative "./connection/shared_examples/stream"
require_relative "./connection/shared_examples/subdomain"
require_relative "./connection/shared_examples/type"
require_relative "./connection/shared_examples/write"

RSpec.shared_examples :connection do
  let :scheme do
    "http"
  end

  let :subdomain do
    "www"
  end

  let :host do
    "localhost"
  end

  let :port do
    "4242"
  end

  let :method do
    "GET"
  end

  let :path do
    "/"
  end

  let :params do
    {}
  end

  let :query do
    "?foo=bar"
  end

  let :headers do
    {}
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:output, level: 2, verbose!: nil)
    )
  end

  describe "known events" do
    it "include finalize"
  end

  describe "#initialize" do
    it "initializes" do
      expect(connection).to be_instance_of(described_class)
    end

    it "sets the connection id" do
      id = "1234"
      allow(SecureRandom).to receive(:hex).and_call_original
      allow(SecureRandom).to receive(:hex).at_least(:once).with(4).and_return(id)
      expect(connection.id).to eq(id)
    end

    it "sets the connection timestamp" do
      timestamp = Time.now
      allow(Time).to receive(:now).and_return(timestamp)
      expect(connection.timestamp).to eq(timestamp)
    end

    it "creates a new http request logger" do
      expect(connection.logger).to be_instance_of(Pakyow::Logger)
      expect(connection.logger.type).to be(:http)
      expect(connection.logger.id).to be(connection.id)
      expect(connection.logger.started_at).to be(connection.timestamp)
    end
  end

  describe "#finalize" do
    it "sets cookies"
    it "returns a response"

    describe "response" do
      it "contains the connection status"
      it "contains the connection headers"
      it "contains the connection body"
    end

    context "response is set on the connection" do
      it "returns the correct response"
    end

    context "streaming" do
      it "waits for each stream in an async task" do
        Async::Reactor.run {
          streams = connection.stream do
            connection.sleep(0.01)
          end

          streams.each do |stream|
            expect(stream).to receive(:wait)
          end

          connection.finalize
        }.wait
      end

      it "closes the body once the streams stop" do
        Async::Reactor.run {
          connection.stream do
            connection.sleep(0.01)
          end

          expect(connection.body).to receive(:close) do
            expect(connection.streaming?).to be(false)
          end

          expect(connection.streaming?).to be(true)
          connection.finalize
        }.wait
      end
    end

    context "HEAD request" do
      before do
        expect(connection).to receive(:request_method).and_return("HEAD")
      end

      it "closes the body"
      it "replaces the body with an empty body"

      context "streaming" do
        it "stops the streaming tasks before closing" do
          Async::Reactor.run {
            streams = connection.stream do
              connection.sleep(0.01)
            end

            streams.each do |stream|
              expect(stream).to receive(:stop)
            end

            expect(connection.body).to receive(:close) do
              expect(connection.streaming?).to be(false)
            end

            expect(connection.streaming?).to be(true)
            connection.finalize
          }.wait
        end
      end
    end
  end

  it_behaves_like :connection_authority
  it_behaves_like :connection_body
  it_behaves_like :connection_close
  it_behaves_like :connection_cookies
  it_behaves_like :connection_endpoint
  it_behaves_like :connection_format
  it_behaves_like :connection_fullpath
  it_behaves_like :connection_headers
  it_behaves_like :connection_host
  it_behaves_like :connection_input
  it_behaves_like :connection_ip
  it_behaves_like :connection_method
  it_behaves_like :connection_params
  it_behaves_like :connection_path
  it_behaves_like :connection_port
  it_behaves_like :connection_query
  it_behaves_like :connection_request
  it_behaves_like :connection_scheme
  it_behaves_like :connection_secure
  it_behaves_like :connection_sleep
  it_behaves_like :connection_status
  it_behaves_like :connection_stream
  it_behaves_like :connection_subdomain
  it_behaves_like :connection_type
  it_behaves_like :connection_write
end

RSpec.describe Pakyow::Connection do
  it_behaves_like :connection do
    let :connection do
      described_class.new(request)
    end

    let :request do
      Async::HTTP::Protocol::Request.new(
        scheme, "#{subdomain}.#{host}:#{port}", method, "#{path}#{query}", "HTTP/1.1", Protocol::HTTP::Headers.new(headers.to_a)
      ).tap do |request|
        request.remote_address = Addrinfo.tcp("127.0.0.1", scheme)
      end
    end

    describe "#hijack?" do
      it "returns the value from the request" do
        expect(connection.request).to receive(:hijack?).and_return(true)
        expect(connection.hijack?).to be(true)
      end
    end

    describe "#hijack!" do
      it "calls hijack on the request" do
        connection.instance_variable_set(:@request, double(hijack!: :io))
        expect(connection.hijack!).to eq(:io)
      end
    end
  end
end

require "pakyow/rack/compatibility"
RSpec.describe Pakyow::Rack::Connection do
  it_behaves_like :connection do
    let :connection do
      described_class.new(rack_env)
    end

    let :rack_env do
      normalized_headers = Hash[headers.to_h.map { |key, value|
        [key.to_s.upcase.gsub("-", "_"), value]
      }]

      normalized_headers["REMOTE_ADDR"] = "127.0.0.1"

      if normalized_headers.key?("X_FORWARDED_FOR")
        normalized_headers["HTTP_X_FORWARDED_FOR"] = normalized_headers.delete("X_FORWARDED_FOR")
      end

      Rack::MockRequest.env_for(
        "#{scheme}://#{subdomain}.#{host}:#{port}#{path}#{query}",
        { method: method, params: params }.merge(normalized_headers)
      )
    end

    it "sets rack.logger to request logger" do
      skip

      # action.call(connection) {}
      # expect(env["rack.logger"]).to be(logger)
    end

    describe "#hijack?" do
      context "request is hijackable" do
        before do
          rack_env["rack.hijack?"] = true
        end

        it "returns true" do
          expect(connection.hijack?).to be(true)
        end
      end

      context "request is not hijackable" do
        before do
          rack_env["rack.hijack?"] = false
        end

        it "returns false" do
          expect(connection.hijack?).to be(false)
        end
      end
    end

    describe "#hijack!" do
      before do
        rack_env["rack.hijack"] = Proc.new { :hijacked }
      end

      it "calls the hijack block" do
        expect(connection.hijack!).to eq(:hijacked)
      end
    end
  end
end
