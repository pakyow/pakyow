RSpec.describe Pakyow::Actions::Restart do
  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", method, path, nil
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :path do
    ""
  end

  def call
    described_class.new.call(connection)
  end

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:open)
    allow(connection).to receive(:halt)
  end

  context "path: /pw-restart, method: post and mode is passed" do
    let :path do
      "/pw-restart?environment=prototype"
    end

    let :method do
      "POST"
    end

    it "tells pakyow to restart" do
      expect(Pakyow).to receive(:restart).with(env: "prototype")

      call
    end

    it "halts the connection" do
      expect(connection).to receive(:halt)
      call
    end
  end

  context "path is not /pw-restart" do
    let :path do
      "/pw-?environment=prototype"
    end

    let :method do
      "POST"
    end

    it "does not restart" do
      expect(Pakyow).not_to receive(:restart)

      call
    end
  end

  context "method is not post" do
    let :path do
      "/pw-?environment=prototype"
    end

    let :method do
      "GET"
    end

    it "does not restart" do
      expect(Pakyow).not_to receive(:restart)

      call
    end
  end

  context "mode is not passed" do
    let :path do
      "/pw-restart"
    end

    let :method do
      "POST"
    end

    it "does not restart" do
      expect(Pakyow).not_to receive(:restart)

      call
    end
  end
end
