require_relative "shared_examples/expire"
require_relative "shared_examples/handler"
require_relative "shared_examples/persist"
require_relative "shared_examples/subscribe"
require_relative "shared_examples/subscribe_associated"
require_relative "shared_examples/subscribe_associated_conditional"
require_relative "shared_examples/subscribe_command"
require_relative "shared_examples/subscribe_conditional"
require_relative "shared_examples/subscribe_many"
require_relative "shared_examples/unsubscribe"

RSpec.shared_examples "data subscriptions" do
  include_examples :subscription_expire
  include_examples :subscription_handler
  include_examples :subscription_persist
  include_examples :subscription_subscribe
  include_examples :subscription_subscribe_associated
  include_examples :subscription_subscribe_associated_conditional
  include_examples :subscription_subscribe_command
  include_examples :subscription_subscribe_conditional
  include_examples :subscription_subscribe_many
  include_examples :subscription_unsubscribe
end
