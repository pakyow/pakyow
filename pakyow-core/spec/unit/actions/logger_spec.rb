RSpec.describe Pakyow::Actions::Logger do
  let :action do
    Pakyow::Actions::Logger.new
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    instance_double(Async::HTTP::Protocol::Request)
  end

  let :logger do
    double.as_null_object
  end

  before do
    allow(Pakyow::Logger).to receive(:new).and_return(logger)
  end

  it "logs the prologue" do
    expect(logger).to receive(:prologue).with(connection)
    action.call(connection) {}
  end

  it "logs the epilogue" do
    expect(logger).to receive(:epilogue).with(connection)
    action.call(connection) {}
  end

  it "yields between prologue and epilogue" do
    allow(logger).to receive(:prologue)
    allow(logger).to receive(:epilogue)

    yielded = false
    action.call(connection) do
      yielded = true
      expect(logger).to have_received(:prologue).with(connection)
      expect(logger).not_to have_received(:epilogue)
    end

    expect(yielded).to be(true)
    expect(logger).to have_received(:epilogue).with(connection)
  end

  context "silencer exists" do
    let :output do
      double(:output, level: 2)
    end

    let :logger do
      Pakyow::Logger.new(:http, output: output)
    end

    before do
      Pakyow.silence do |connection|
        connection.path.include?("foo")
      end
    end

    after do
      Pakyow.silencers.clear
    end

    context "silencer is matched" do
      let :request do
        instance_double(Async::HTTP::Protocol::Request, path: "/foo")
      end

      it "silences log output" do
        expect(logger).to receive(:prologue) do
          expect(logger.level).to eq(Pakyow::Logger::NICE_LEVELS.key(:error))
        end

        expect(logger).to receive(:epilogue) do
          expect(logger.level).to eq(Pakyow::Logger::NICE_LEVELS.key(:error))
        end

        action.call(connection) {}
      end
    end

    context "silencer is not matched" do
      let :request do
        instance_double(Async::HTTP::Protocol::Request, path: "/bar")
      end

      it "does not silence log output" do
        expect(logger).to receive(:prologue)
        expect(logger).to receive(:epilogue)
        action.call(connection) {}
      end
    end
  end
end
