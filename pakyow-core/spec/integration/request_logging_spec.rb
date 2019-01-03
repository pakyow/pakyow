RSpec.describe "using the request logger" do
  let :request_logger do
    Pakyow::RequestLogger.new(:http, logger: logger)
  end

  let :logger do
    Pakyow::Logger.new(io).tap do |logger|
      logger.formatter = formatter
    end
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

  let :env do
    {
      Rack::REQUEST_METHOD => "GET",
      Pakyow::RequestLogger::REQUEST_URI => "/",
      "REMOTE_ADDR" => "0.0.0.0",
      time: datetime
    }
  end

  let :res do
    [200, "", {}]
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
    allow(request_logger).to receive(:elapsed).and_return(elapsed)
  end

  context "formatter is human" do
    let :formatter do
      require "pakyow/logger/formatters/human"
      Pakyow::Logger::Formatters::Human.new
    end

    it "logs a message" do
      request_logger.debug "foo"
      expect(message).to eq("\e[36m  #{elapsed}.00s  http.#{request_logger.id} | foo\n\e[0m")
    end

    it "logs the prologue" do
      request_logger.prologue(env)
      expect(message).to eq("\e[32m  #{elapsed}.00s  http.#{request_logger.id} | GET / (for 0.0.0.0 at #{datetime})\n\e[0m")
    end

    it "logs the epilogue" do
      request_logger.epilogue(res)
      expect(message).to eq("\e[32m  #{elapsed}.00s  http.#{request_logger.id} | 200 (OK)\n\e[0m")
    end

    it "logs an error" do
      allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return("error")
      request_logger.houston(error)
      expect(message).to eq("\e[31m  #{elapsed}.00s  http.#{request_logger.id} | error\n\e[0m")
    end
  end

  context "formatter is json" do
    let :formatter do
      require "pakyow/logger/formatters/json"
      Pakyow::Logger::Formatters::JSON.new
    end

    it "logs a message" do
      request_logger.debug "foo"
      expect(message).to eq("{\"severity\":\"DEBUG\",\"timestamp\":\"#{datetime}\",\"id\":\"#{request_logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"message\":\"foo\"}\n")
    end

    it "logs the prologue" do
      request_logger.prologue(env)
      expect(message).to eq("{\"severity\":\"INFO\",\"timestamp\":\"#{datetime}\",\"id\":\"#{request_logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"method\":\"GET\",\"uri\":\"/\",\"ip\":\"0.0.0.0\"}\n")
    end

    it "logs the epilogue" do
      request_logger.epilogue(res)
      expect(message).to eq("{\"severity\":\"INFO\",\"timestamp\":\"#{datetime}\",\"id\":\"#{request_logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"status\":200}\n")
    end

    it "logs an error" do
      allow(error).to receive(:backtrace).and_return(["one"])
      request_logger.houston(error)
      expect(message).to eq("{\"severity\":\"ERROR\",\"timestamp\":\"#{datetime}\",\"id\":\"#{request_logger.id}\",\"type\":\"http\",\"elapsed\":\"#{elapsed * 1000}.00ms\",\"exception\":\"Pakyow::Error\",\"message\":\"foo\",\"backtrace\":[\"one\"]}\n")
    end
  end

  context "formatter is logfmt" do
    let :formatter do
      require "pakyow/logger/formatters/logfmt"
      Pakyow::Logger::Formatters::Logfmt.new
    end

    it "logs a message" do
      request_logger.debug "foo"
      expect(message).to eq("severity=DEBUG timestamp=\"#{datetime}\" id=#{request_logger.id} type=http elapsed=#{elapsed * 1000}.00ms message=foo\n")
    end

    it "logs the prologue" do
      request_logger.prologue(env)
      expect(message).to eq("severity=INFO timestamp=\"#{datetime}\" id=#{request_logger.id} type=http elapsed=#{elapsed * 1000}.00ms method=GET uri=/ ip=0.0.0.0\n")
    end

    it "logs the epilogue" do
      request_logger.epilogue(res)
      expect(message).to eq("severity=INFO timestamp=\"#{datetime}\" id=#{request_logger.id} type=http elapsed=#{elapsed * 1000}.00ms status=200\n")
    end

    it "logs an error" do
      allow(error).to receive(:backtrace).and_return(["one"])
      request_logger.houston(error)
      expect(message).to eq("severity=ERROR timestamp=\"#{datetime}\" id=#{request_logger.id} type=http elapsed=#{elapsed * 1000}.00ms exception=Pakyow::Error message=foo backtrace=one\n")
    end
  end
end
