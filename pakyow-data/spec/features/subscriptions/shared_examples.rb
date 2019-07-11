require_relative "shared_examples/expire"
require_relative "shared_examples/handler"
require_relative "shared_examples/persist"
require_relative "shared_examples/subscribe"
require_relative "shared_examples/subscribe_associated"
require_relative "shared_examples/subscribe_associated_conditional"
require_relative "shared_examples/subscribe_command"
require_relative "shared_examples/subscribe_compound"
require_relative "shared_examples/subscribe_conditional"
require_relative "shared_examples/subscribe_deeply_associated"
require_relative "shared_examples/subscribe_ephemeral"
require_relative "shared_examples/subscribe_many"
require_relative "shared_examples/unsubscribe"
require_relative "shared_examples/version"

RSpec.shared_examples "data subscriptions" do
  it_behaves_like :subscription_expire
  it_behaves_like :subscription_handler
  it_behaves_like :subscription_persist
  it_behaves_like :subscription_subscribe
  it_behaves_like :subscription_subscribe_associated
  it_behaves_like :subscription_subscribe_associated_conditional
  it_behaves_like :subscription_subscribe_command
  it_behaves_like :subscription_subscribe_compound
  it_behaves_like :subscription_subscribe_conditional
  it_behaves_like :subscription_subscribe_deeply_associated
  it_behaves_like :subscription_subscribe_ephemeral
  it_behaves_like :subscription_subscribe_many
  it_behaves_like :subscription_unsubscribe
  it_behaves_like :subscription_version
end
