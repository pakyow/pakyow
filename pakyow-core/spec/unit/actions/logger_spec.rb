RSpec.describe Pakyow::Actions::Logger do
  let :action do
    Pakyow::Actions::Logger.new
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    instance_double(Async::HTTP::Protocol::Request, method: "GET", path: "/", headers: {}, remote_address: remote_address)
  end

  let(:remote_address) {
    double(:remote_address, ip_address: "1.2.3.4")
  }

  before do
    allow(Pakyow.logger).to receive(:prologue)
    allow(Pakyow.logger).to receive(:epilogue)
    allow(Pakyow.logger).to receive(:debug)
  end

  it "logs the prologue" do
    expect(Pakyow.logger).to receive(:prologue).with(connection)

    connection.async do
      action.call(connection) {}
    end
  end

  it "logs the epilogue" do
    expect(Pakyow.logger).to receive(:epilogue).with(connection)

    connection.async do
      action.call(connection) {}
    end
  end

  it "yields between prologue and epilogue" do
    allow(Pakyow.logger).to receive(:prologue)
    allow(Pakyow.logger).to receive(:epilogue)

    yielded = false
    connection.async do
      action.call(connection) do
        yielded = true
        expect(Pakyow.logger).to have_received(:prologue).with(connection)
        expect(Pakyow.logger).not_to have_received(:epilogue)
      end
    end

    expect(yielded).to be(true)
    expect(Pakyow.logger).to have_received(:epilogue).with(connection)
  end

  context "silencer exists" do
    let :output do
      double(:output, verbose!: nil)
    end

    let :logger do
      Pakyow::Logger.new(:http, output: output, level: :info)
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
        instance_double(Async::HTTP::Protocol::Request, method: "GET", path: "/foo", headers: {}, remote_address: remote_address)
      end

      it "silences log output" do
        expect(Pakyow.logger).to receive(:prologue) do
          expect(Pakyow.logger.level).to eq(4)
        end

        expect(Pakyow.logger).to receive(:epilogue) do
          expect(Pakyow.logger.level).to eq(4)
        end

        connection.async do
          action.call(connection) {}
        end
      end
    end

    context "silencer is not matched" do
      let :request do
        instance_double(Async::HTTP::Protocol::Request, method: "GET", path: "/bar", headers: {}, remote_address: remote_address)
      end

      it "does not silence log output" do
        expect(Pakyow.logger).to receive(:prologue)
        expect(Pakyow.logger).to receive(:epilogue)

        connection.async do
          action.call(connection) {}
        end
      end
    end
  end
end
