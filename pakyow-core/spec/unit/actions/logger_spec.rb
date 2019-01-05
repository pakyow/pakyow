RSpec.describe Pakyow::Actions::Logger do
  let :app do
    instance_double(Pakyow::App)
  end

  let :action do
    Pakyow::Actions::Logger.new
  end

  let :connection do
    Pakyow::Connection.new(app, env)
  end

  let :env do
    {}
  end

  let :logger do
    double.as_null_object
  end

  before do
    allow(Pakyow::RequestLogger).to receive(:new).and_return(logger)
  end

  it "creates a new http request logger" do
    expect(Pakyow::RequestLogger).to receive(:new).with(:http, id: connection.id, started_at: connection.timestamp)
    action.call(connection) {}
  end

  it "sets rack.logger to request logger" do
    action.call(connection) {}
    expect(env["rack.logger"]).to be(logger)
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

  context "connection has already been pipelined" do
    before do
      connection.pipelined
    end

    it "does not log the prologue" do
      expect(logger).not_to receive(:prologue)
      action.call(connection) {}
    end

    it "does not log the epilogue" do
      expect(logger).not_to receive(:epilogue)
      action.call(connection) {}
    end
  end

  context "silencer exists" do
    let :io do
      StringIO.new
    end

    let :logger do
      Pakyow::RequestLogger.new(:http, logger: Pakyow::Logger.new(io))
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
      let :env do
        { Rack::PATH_INFO => "/foo" }
      end

      it "silences log output" do
        expect(logger).to receive(:prologue) do
          expect(logger.logger.level).to eq(Logger::ERROR)
        end

        expect(logger).to receive(:epilogue) do
          expect(logger.logger.level).to eq(Logger::ERROR)
        end

        action.call(connection) {}
      end
    end

    context "silencer is not matched" do
      let :env do
        { Rack::PATH_INFO => "/bar" }
      end

      it "does not silence log output" do
        expect(logger).to receive(:prologue)
        expect(logger).to receive(:epilogue)
        action.call(connection) {}
      end
    end
  end
end
