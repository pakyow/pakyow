require "pakyow/logger"

RSpec.describe Pakyow::Logger do
  let :type do
    :http
  end

  let :output do
    double(:output, call: nil, verbose!: nil)
  end

  let :level do
    :info
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
    described_class.new(type, output: output, level: level)
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
      "http", "localhost", "GET", "/", nil, Protocol::HTTP::Headers.new([])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("127.0.0.1", "http")
    end
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:global_output, call: nil, verbose!: nil)
    )
  end

  describe "#initialize" do
    describe "argument: type" do
      it "is required" do
        expect { described_class.new(output: output, level: level) }.to raise_error(ArgumentError)
      end

      it "is set on the instance" do
        expect(instance.type).to be(type)
      end
    end

    describe "argument: output" do
      it "is required" do
        expect { described_class.new(type, level: level) }.to raise_error(ArgumentError)
      end

      it "is set on the instance" do
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
        instance = described_class.new(type, id: id, output: output, level: level)
        expect(instance.id).to be(id)
      end
    end

    describe "level" do
      it "can be passed as an integer" do
        instance = described_class.new(type, output: output, level: 4)
        expect(instance.level).to eq(4)
      end

      it "can be passed as a symbol" do
        instance = described_class.new(type, output: output, level: :internal)
        expect(instance.level).to eq(0)
      end

      it "can be passed as a string" do
        instance = described_class.new(type, output: output, level: "internal")
        expect(instance.level).to eq(0)
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

    %i(internal debug info warn error fatal unknown).each do |method|
      let :level do
        :internal
      end

      describe "##{method}" do
        it "calls #{method} on the output with a block that returns a decorated message" do
          expect(output).to receive(:call) do |_, options, &block|
            expect(options[:severity]).to eq(method)
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
        expect(output).to receive(:call) do |_, options, &block|
          expect(options[:severity]).to eq(:unknown)
          expect(block.call).to be(decorated)
        end

        instance << message
      end
    end

    %i(add log).each do |method|
      describe "##{method}" do
        it "calls add on the output with the given severity and a block that returns a decorated message" do
          expect(output).to receive(:call) do |_, options, &block|
            expect(options[:severity]).to eq(:info)
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
      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:info)
        expect(block.call["message"]).to include("prologue" => connection)
      end

      instance.prologue(connection)
    end
  end

  describe "#epilogue" do
    it "logs the epilogue at the proper level" do
      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:info)
        expect(block.call["message"]).to include("epilogue" => connection)
      end

      instance.epilogue(connection)
    end
  end

  describe "#houston" do
    let :err do
      ArgumentError.new
    end

    it "logs the error at the proper level" do
      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:error)
        expect(block.call["message"]).to include("error" => err)
      end

      instance.houston(err)
    end
  end

  describe "#silence" do
    before do
      allow(Pakyow).to receive(:deprecated)
    end

    it "is deprecated" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        instance, :silence, solution: "use `Pakyow::Logger::ThreadLocal#silence'"
      )

      instance.silence do; end
    end

    it "does not log messages below error by default" do
      expect(output).not_to receive(:warn)

      instance.silence do
        instance.warn "test_warn"
      end
    end

    it "logs messages at error or above by default" do
      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:error)
        expect(block.call).to include("message" => "test_error")
      end

      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:fatal)
        expect(block.call).to include("message" => "test_fatal")
      end

      expect(output).to receive(:call) do |_, options, &block|
        expect(options[:severity]).to eq(:unknown)
        expect(block.call).to include("message" => "test_unknown")
      end

      instance.silence do
        instance.error "test_error"
        instance.fatal "test_fatal"
        instance.unknown "test_unknown"
      end
    end

    context "temporary level is passed" do
      it "does not log messages below the passed level" do
        expect(output).not_to receive(:call)

        instance.silence :warn do
          instance.info "test_info"
        end
      end

      it "logs messages at or above the passed level" do
        expect(output).to receive(:call) do |_, options, &block|
          expect(options[:severity]).to eq(:warn)
          expect(block.call).to include("message" => "test_warn")
        end

        expect(output).to receive(:call) do |_, options, &block|
          expect(options[:severity]).to eq(:error)
          expect(block.call).to include("message" => "test_error")
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

  describe "setting the log level to all" do
    let :level do
      :all
    end

    it "sets the appropriate level" do
      expect(instance.level).to eq(0)
    end
  end

  describe "setting the log level to off" do
    let :level do
      :off
    end

    it "sets the appropriate level" do
      expect(instance.level).to eq(7)
    end
  end

  describe "::null" do
    before do
      allow(described_class).to receive(:new).with(:null, output: instance_of(StringIO), level: :off).and_return(null_logger)
    end

    let(:null_logger) {
      instance_double(described_class)
    }

    it "returns a null logger" do
      expect(described_class.null).to be(null_logger)
    end
  end
end
