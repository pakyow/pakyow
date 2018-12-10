require_relative "shared_examples"

RSpec.describe "using data subscriptions with the redis adapter" do
  let :data_subscription_adapter do
    :redis
  end

  after do
    if defined?(Redis)
      Redis.new.flushdb
    end
  end

  include_examples "data subscriptions"
end
