require "pakyow/request_logger"

RSpec.describe Pakyow::RequestLogger do
  let :klass do
    Pakyow::RequestLogger
  end

  let :type do
    :http
  end

  let :logger do
    instance_double(Pakyow::Logger, formatter: formatter)
  end

  let :formatter do
    double(
      :formatter,
      format_epilogue: "formatted epilogue",
      format_request: "formatted request",
      format_error: "formatted error"
    )
  end

  let :instance do
    klass.new(type)
  end

  let :env do
    {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "REMOTE_ADDR" => "0.0.0.0",
    }
  end

  let :connection do
    Pakyow::Connection.new(instance_double(Pakyow::App), env)
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

    %i(<< debug error fatal info unknown warn).each do |method|
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

    %i(add log).each do |method|
      describe "##{method}" do
        it "calls add on logger with decorated message at the given severity" do
          expect(instance).to receive(:decorate).with(message).and_return(decorated)
          expect(logger).to receive(:add).with(2, decorated)
          instance.send(method, 2, message)
        end
      end
    end
  end

  describe "#prologue" do
    it "logs the prologue at the proper level" do
      expect(logger.formatter).to receive(:format_prologue).with(
        connection
      ).and_return("formatted prologue")

      expect(instance).to receive(:info) do |message|
        expect(message).to eq("formatted prologue")
      end

      instance.prologue(connection)
    end
  end

  describe "#epilogue" do
    it "logs the epilogue at the proper level" do
      expect(logger.formatter).to receive(:format_epilogue).with(
        connection
      ).and_return("formatted epilogue")

      expect(instance).to receive(:info).with("formatted epilogue")
      instance.epilogue(connection)
    end
  end

  describe "#houston" do
    let :err do
      ArgumentError.new
    end

    it "logs the error at the proper level" do
      expect(logger.formatter).to receive(:format_error) { |error_to_format|
        expect(error_to_format.wrapped_exception).to be(err)
        "formatted error"
      }

      expect(instance).to receive(:error).with("formatted error")
      instance.houston(err)
    end
  end

  describe "decorating the message" do
    let :message do
      ""
    end

    after do
      instance << message
    end

    it "lets the formatter decorate the message" do
      expect(logger.formatter).to receive(:format_message) { |received_message, **kwargs|
        expect(received_message).to be(message)
        expect(kwargs[:id]).to be(instance.id)
        expect(kwargs[:type]).to be(instance.type)
        expect(kwargs[:elapsed]).to be_between(0.0, 1.0)
        "formatted request"
      }

      expect(logger).to receive(:<<).with("formatted request")
    end
  end

  describe "#silence" do
    let :logger do
      double.as_null_object
    end

    it "sets the log level to the temporary level" do
      expect(logger).to receive(:level=).with(Pakyow::Logger::ERROR)
      instance.silence do; end
    end

    it "yields while the temporary level is active" do
      logger = Pakyow::Logger.new("/dev/null")
      instance.instance_variable_set(:@logger, logger)

      yielded_level = nil
      instance.silence do
        yielded_level = logger.level
      end

      expect(yielded_level).to eq(Pakyow::Logger::ERROR)
    end

    it "sets the log level back to the original level" do
      original_level = logger.level
      instance.silence do; end
      expect(logger.level).to eq(original_level)
    end
  end
end
