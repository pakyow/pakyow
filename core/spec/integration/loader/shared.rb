require "pakyow/support/definable"

RSpec.shared_context "loader" do
  let(:target) {
    stub_const("Target", target_class)

    target_class
  }

  let(:target_class) {
    local = self

    Class.new {
      include Pakyow::Support::Definable

      definable :state, local.state
    }
  }

  let(:state) {
    stub_const("State", state_class)

    state_class
  }

  let(:state_class) {
    Class.new
  }

  let(:loader) {
    Pakyow::Loader.new(loader_path)
  }

  let(:autoload) {
    true
  }

  before do
    loader.call(target) if autoload
  end
end
