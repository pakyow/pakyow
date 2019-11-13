RSpec.describe "request logging" do
  let :logger do
    Pakyow::Logger.new(:http, output: Pakyow.output, level: Pakyow.config.logger.level)
  end

  let :io do
    StringIO.new
  end

  let :elapsed do
    (1..5).to_a.sample
  end

  let :datetime do
    Time.now
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, Protocol::HTTP::Headers.new([["content-type", "text/html"]])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :error do
    begin
      raise "foo"
    rescue => error
      return error
    end
  end

  let :message do
    io.rewind
    io.read
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      formatter.new(Pakyow::Logger::Destination.new(:io, io))
    )

    allow(logger).to receive(:elapsed).and_return(elapsed)
  end

  context "formatter is human" do
    let :formatter do
      require "pakyow/logger/formatters/human"
      Pakyow::Logger::Formatters::Human
    end

    it "logs a message" do
      logger.debug "foo"
      expect(message).to eq("\e[36m  #{elapsed}.00s  http.#{logger.id} | foo\e[0m\n")
    end

    it "logs the prologue" do
      logger.prologue(connection)
      expect(message).to eq("\e[32m  #{elapsed}.00s  http.#{logger.id} | GET / (for 0.0.0.0 at #{datetime})\e[0m\n")
    end

    it "logs the epilogue" do
      logger.epilogue(connection)
      expect(message).to eq("\e[32m  #{elapsed}.00s  http.#{logger.id} | 200 (OK)\e[0m\n")
    end

    it "logs an error" do
      allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return("error")
      logger.houston(error)
      expect(message).to eq("\e[31m  #{elapsed}.00s  http.#{logger.id} | error\e[0m\n")
    end
  end

  context "formatter is json" do
    let :formatter do
      require "pakyow/logger/formatters/json"
      Pakyow::Logger::Formatters::JSON
    end

    it "logs a message" do
      logger.debug "foo"
      expect(message).to eq("{\"severity\":\"debug\",\"timestamp\":\"#{datetime}\",\"id\":\"#{logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"message\":\"foo\"}\n")
    end

    it "logs the prologue" do
      logger.prologue(connection)
      expect(message).to eq("{\"severity\":\"info\",\"timestamp\":\"#{datetime}\",\"id\":\"#{logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"method\":\"GET\",\"uri\":\"/\",\"ip\":\"0.0.0.0\"}\n")
    end

    it "logs the epilogue" do
      logger.epilogue(connection)
      expect(message).to eq("{\"severity\":\"info\",\"timestamp\":\"#{datetime}\",\"id\":\"#{logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"status\":200}\n")
    end

    it "logs an error" do
      allow(error).to receive(:backtrace).and_return(["one"])
      logger.houston(error)
      expect(message).to eq("{\"severity\":\"error\",\"timestamp\":\"#{datetime}\",\"id\":\"#{logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"exception\":\"RuntimeError\",\"message\":\"foo\",\"backtrace\":[\"one\"]}\n")
    end
  end

  context "formatter is logfmt" do
    let :formatter do
      require "pakyow/logger/formatters/logfmt"
      Pakyow::Logger::Formatters::Logfmt
    end

    it "logs a message" do
      logger.debug "foo"
      expect(message).to eq("severity=debug timestamp=\"#{datetime}\" id=#{logger.id} type=http elapsed=#{elapsed * 1000}.00ms message=foo\n")
    end

    it "logs the prologue" do
      logger.prologue(connection)
      expect(message).to eq("severity=info timestamp=\"#{datetime}\" id=#{logger.id} type=http elapsed=#{elapsed * 1000}.00ms method=GET uri=/ ip=0.0.0.0\n")
    end

    it "logs the epilogue" do
      logger.epilogue(connection)
      expect(message).to eq("severity=info timestamp=\"#{datetime}\" id=#{logger.id} type=http elapsed=#{elapsed * 1000}.00ms status=200\n")
    end

    it "logs an error" do
      allow(error).to receive(:backtrace).and_return(["one"])
      logger.houston(error)
      expect(message).to eq("severity=error timestamp=\"#{datetime}\" id=#{logger.id} type=http elapsed=#{elapsed * 1000}.00ms exception=RuntimeError message=foo backtrace=one\n")
    end
  end
end
