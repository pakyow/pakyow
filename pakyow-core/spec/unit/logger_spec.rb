require "pakyow/logger"

RSpec.describe Pakyow::Logger do
  let :type do
    :http
  end

  let :global_logger do
    double(:global_logger, level: 2)
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
    described_class.new(type)
  end

  let :env do
    {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "REMOTE_ADDR" => "0.0.0.0",
    }
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, HTTP::Protocol::Headers.new([])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("127.0.0.1", "http")
    end
  end

  before do
    allow(Pakyow).to receive(:global_logger).and_return(global_logger)
  end

  describe "#initialize" do
    describe "argument: type" do
      it "is required" do
        expect { described_class.new }.to raise_error(ArgumentError)
      end

      it "is set on the instance" do
        expect(instance.type).to be(type)
      end
    end

    describe "argument: output" do
      it "defaults to Pakyow.global_logger" do
        expect(instance.output).to be(global_logger)
      end

      it "can be passed" do
        output = double(level: 1)
        instance = described_class.new(type, output: output)
        expect(instance.output).to be(output)
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
        instance = described_class.new(type, id: id)
        expect(instance.id).to be(id)
      end
    end

    describe "level" do
      it "defaults to the level from the output" do
        expect(instance.level).to eq(global_logger.level)
      end

      it "can be passed as an integer" do
        instance = described_class.new(type, level: 4)
        expect(instance.level).to eq(4)
      end

      it "can be passed as a symbol" do
        instance = described_class.new(type, level: :verbose)
        expect(instance.level).to eq(2)
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

    %i(verbose debug info warn error fatal unknown).each do |method|
      describe "##{method}" do
        it "calls #{method} on the output with a block that returns a decorated message" do
          expect(global_logger).to receive(method).with(no_args) do |&block|
            expect(instance).to receive(:decorate).with(message).and_return(decorated)
            expect(block.call).to be(decorated)
          end

          instance.send(method, message)
        end
      end
    end

    describe "#<<" do
      it "calls unknown on the output with the decorated message" do
        expect(instance).to receive(:decorate).with(message).and_return(decorated)
        expect(global_logger).to receive(:unknown) do |&block|
          expect(block.call).to be(decorated)
        end

        instance << message
      end
    end

    %i(add log).each do |method|
      describe "##{method}" do
        it "calls add on the output with the given severity and a block that returns a decorated message" do
          expect(global_logger).to receive(:info) do |&block|
            expect(instance).to receive(:decorate).with(message).and_return(decorated)
            expect(block.call).to be(decorated)
          end

          instance.send(method, :info, message)
        end
      end
    end
  end

  describe "#prologue" do
    it "logs the prologue at the proper level" do
      expect(global_logger).to receive(:info) do |&block|
        expect(block.call[:message]).to include(prologue: connection)
      end

      instance.prologue(connection)
    end
  end

  describe "#epilogue" do
    it "logs the epilogue at the proper level" do
      expect(global_logger).to receive(:info) do |&block|
        expect(block.call[:message]).to include(epilogue: connection)
      end

      instance.epilogue(connection)
    end
  end

  describe "#houston" do
    let :err do
      ArgumentError.new
    end

    it "logs the error at the proper level" do
      expect(global_logger).to receive(:error) do |&block|
        expect(block.call[:message]).to include(error: err)
      end

      instance.houston(err)
    end
  end

  describe "#silence" do
    it "does not log messages below error by default" do
      expect(global_logger).not_to receive(:warn)

      instance.silence do
        instance.warn "test_warn"
      end
    end

    it "logs messages at error or above by default" do
      expect(global_logger).to receive(:error) do |&block|
        expect(block.call).to include(message: "test_error")
      end

      expect(global_logger).to receive(:fatal) do |&block|
        expect(block.call).to include(message: "test_fatal")
      end

      expect(global_logger).to receive(:unknown) do |&block|
        expect(block.call).to include(message: "test_unknown")
      end

      instance.silence do
        instance.error "test_error"
        instance.fatal "test_fatal"
        instance.unknown "test_unknown"
      end
    end

    context "temporary level is passed" do
      it "does not log messages below the passed level" do
        expect(global_logger).not_to receive(:info)

        instance.silence :warn do
          instance.info "test_info"
        end
      end

      it "logs messages at or above the passed level" do
        expect(global_logger).to receive(:warn) do |&block|
          expect(block.call).to include(message: "test_warn")
        end

        expect(global_logger).to receive(:error) do |&block|
          expect(block.call).to include(message: "test_error")
        end

        instance.silence :warn do
          instance.warn "test_warn"
          instance.error "test_error"
        end
      end
    end

    it "sets the log level back to the original level" do
      original_level = instance.level
      instance.silence do; end
      expect(instance.level).to eq(original_level)
    end
  end
end
