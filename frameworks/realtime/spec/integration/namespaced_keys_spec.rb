RSpec.describe "namespacing keys in the production adapter" do
  include_context "app"

  let :mode do
    :production
  end

  let :redis do
    Redis.new(Pakyow.config.redis.connection.to_h)
  end

  before do
    @existing_keys = redis.keys("*").reject { |key|
      key.start_with?("pw")
    }
  end

  it "namespaces correctly" do
    server = Pakyow::Realtime::Server.new(
      Pakyow.config.realtime.adapter,
      Pakyow.config.realtime.adapter_settings.to_h,
      Pakyow.config.realtime.timeouts
    )

    thread = Thread.new {
      server.run
    }

    Pakyow::Realtime::Server.socket_subscribe("123", "foo")

    until Pakyow::Realtime::Server.queue.empty?
      sleep 1
    end

    keys = redis.keys("*") - @existing_keys
    expect(keys.count).to_not eq(0)

    keys.each do |key|
      expect(key.start_with?("pw")).to be(true)
    end

    server.shutdown
    thread.join
  end
end
