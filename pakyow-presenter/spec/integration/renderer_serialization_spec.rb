RSpec.describe "serializing a renderer" do
  class self::Composer
    def key
      ""
    end

    def view(app:)
      Pakyow::Presenter::View.new("")
    end
  end

  include_context "app"

  let :renderer do
    Pakyow.app(:test).isolated(:Renderer).new(
      app: Pakyow.app(:test),
      presentables: connection.values,
      presenter_class: Pakyow.app(:test).isolated(:Presenter),
      composer: self.class::Composer.new
    )
  end

  let :connection do
    Pakyow.app(:test).isolated(:Connection).new(
      Pakyow.app(:test),
      Pakyow::Connection.new(
        request
      )
    )
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, Protocol::HTTP::Headers.new([["content-type", "text/html"]])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  it "can be serialized" do
    expect { Marshal.dump(renderer) }.not_to raise_error
  end

  it "can be deserialized" do
    expect { Marshal.load(Marshal.dump(renderer)) }.not_to raise_error
  end

  context "connection is included as a presentable" do
    before do
      connection.set(:connection, connection)
    end

    it "does not serialize the connection" do
      deserialized = Marshal.load(Marshal.dump(renderer))
      expect(deserialized.presentables.keys).to_not include(:connection)
    end
  end
end
