require "pakyow/plugin"

RSpec.describe "failure caused by plugging an unknown plugin" do
  before do
    Class.new(Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin")))
  end

  include_context "app"

  let(:app_def) {
    Proc.new {
      plug :foo, at: "/"
    }
  }

  let(:allow_application_rescues) { true }

  it "reports the failure after boot" do
    expect(Pakyow.app(:test).rescued?).to be(true)
    expect(Pakyow.app(:test).rescued.message).to eq("`foo' is not a known plugin")
    expect(Pakyow.app(:test).rescued.contextual_message).to eq(
      <<~MESSAGE
        Try using one of these available plugins:

          - :testable

      MESSAGE
    )
  end
end
