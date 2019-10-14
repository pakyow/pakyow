RSpec.describe "namespacing keys in the production subscription adapter" do
  include_context "app"

  let :mode do
    :production
  end

  let :redis do
    Redis.new(Pakyow.config.redis.connection.to_h)
  end

  before do
    @existing_keys = redis.keys("*").reject { |key|
      key.start_with?("pw/test")
    }
  end

  after do
    if defined?(Redis)
      Redis.new.flushdb
    end
  end

  it "namespaces correctly" do
    Pakyow.apps[0].data.subscribers.register_subscriptions(
      [{}]
    )

    keys = redis.keys("*") - @existing_keys
    expect(keys.count).to_not eq(0)
    keys.each do |key|
      expect(key.start_with?("pw/test")).to be(true)
    end
  end
end
