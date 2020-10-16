require_relative "shared_examples"

RSpec.describe "using data subscriptions with the memory adapter" do
  let :data_subscription_adapter do
    :memory
  end

  let :data_subscription_adapter_settings do
    {}
  end

  include_examples "data subscriptions"
end
