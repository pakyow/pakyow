require "pakyow/logger/request_logger"

RSpec.describe Pakyow::Logger::RequestLogger do
  let :klass do
    Pakyow::Logger::RequestLogger
  end

  let :type do
    :http
  end

  let :logger do
    double.as_null_object
  end

  let :instance do
    klass.new(type)
  end

  before do
    allow(logger).to receive(:dup).and_return(logger)
    allow(Pakyow).to receive(:logger).and_return(logger)
  end

  describe "#initialize" do
    describe "argument: type" do
      it "is required" do
        expect { klass.new }.to raise_error(ArgumentError)
      end

      it "is set on the instance" do
        expect(instance.type).to be(type)
      end
    end

    describe "argument: logger" do
      it "defaults to a dup of Pakyow.logger" do
        expect(logger).to receive(:dup)
        expect(instance.logger).to be(logger)
      end

      it "can be passed" do
        logger = double
        instance = klass.new(type, logger: logger)
        expect(instance.logger).to be(logger)
      end
    end

    describe "argument: id" do
      it "defaults to SecureRandom.hex" do
        hex = 123
        expect(SecureRandom).to receive(:hex).and_return(hex)
        expect(instance.id).to be(hex)
      end

      it "can be passed" do
        id = double
        instance = klass.new(type, id: id)
        expect(instance.id).to be(id)
      end
    end
  end

  describe "logging methods" do
    let :message do
      "foo"
    end

    let :decorated do
      double
    end

    %i(<< add debug error fatal info log unknown warn).each do |method|
      describe "##{method}" do
        it "calls #{method} on logger with decorated message" do
          expect(instance).to receive(:decorate).with(message).and_return(decorated)
          expect(logger).to receive(method).with(decorated)
          instance.send(method, message)
        end
      end
    end

    describe "#verbose" do
      it "logs the message as verbose" do
        expect(instance).to receive(:decorate).with(message).and_return(decorated)
        expect(logger).to receive(:add).with(-1, decorated)
        instance.verbose(message)
      end
    end
  end

  describe "#prologue" do
    let :env do
      {
        "REQUEST_METHOD" => "GET",
        "REQUEST_PATH" => "/",
        "REMOTE_ADDR" => "0.0.0.0",
      }
    end

    it "logs the prologue at the proper level" do
      expect(logger).to receive(:info) do |message|
        expect(message[:prologue]).to eq(
          {
            time: instance.start,
            method: env["REQUEST_METHOD"],
            uri: env["REQUEST_URI"],
            ip: env["REMOTE_ADDR"],
          }
        )
      end

      instance.prologue(env)
    end
  end

  describe "#epilogue" do
    let :res do
      [200, [], {}]
    end

    it "logs the epilogue at the proper level" do
      expect(logger).to receive(:info) do |message|
        expect(message[:epilogue]).to eq(
          {
            status: res[0]
          }
        )
      end

      instance.epilogue(res)
    end
  end

  describe "#houston" do
    let :err do
      ArgumentError.new
    end

    it "logs the error at the proper level" do
      expect(logger).to receive(:error) do |message|
        expect(message[:error]).to eq(err)
      end

      instance.houston(err)
    end
  end

  describe "decorated message" do
    let :message do
      ""
    end

    after do
      instance << message
    end

    it "contains elapsed time" do
      expect(logger).to receive(:<<) do |message|
        expect(message[:elapsed]).to be_between(0.0, 1.0)
      end
    end

    it "contains the request id" do
      expect(logger).to receive(:<<) do |message|
        expect(message[:request][:id]).to be(instance.id)
      end
    end

    it "contains the request type" do
      expect(logger).to receive(:<<) do |message|
        expect(message[:request][:type]).to be(instance.type)
      end
    end

    context "when message is a hash" do
      let :message do
        { foo: "bar" }
      end

      it "merges the message" do
        expect(logger).to receive(:<<) do |message|
          expect(message[:foo]).to eq("bar")
        end
      end
    end

    context "when message is a string" do
      let :message do
        "bar"
      end

      it "merges the message" do
        expect(logger).to receive(:<<) do |message|
          expect(message[:message]).to eq("bar")
        end
      end
    end
  end

  describe "#silence" do
    it "sets the log level to the temporary level" do
      expect(logger).to receive(:level=).with(::Logger::ERROR)
      instance.silence do; end
    end

    it "yields while the temporary level is active" do
      logger = ::Logger.new("/dev/null")
      instance.instance_variable_set(:@logger, logger)

      yielded_level = nil
      instance.silence do
        yielded_level = logger.level
      end

      expect(yielded_level).to eq(::Logger::ERROR)
    end

    it "sets the log level back to the original level" do
      original_level = logger.level
      instance.silence do; end
      expect(logger.level).to eq(original_level)
    end
  end
end
