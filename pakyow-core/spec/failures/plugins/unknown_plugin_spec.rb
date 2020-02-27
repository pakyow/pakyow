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

  let(:autorun) {
    false
  }

  it "reports the failure after boot" do
    expect {
      setup_and_run
    }.to raise_error(Pakyow::ApplicationError) do |error|
      expect(error.cause).to be_instance_of(Pakyow::UnknownPlugin)
      expect(error.cause.message).to eq("`foo' is not a known plugin")
      expect(error.cause.contextual_message).to eq(
        <<~MESSAGE
          Try using one of these available plugins:

            - :testable

        MESSAGE
      )
    end
  end
end
