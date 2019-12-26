require "pakyow/plugin"

RSpec.describe "failure caused by plugging an unknown plugin" do
  before do
    Class.new(Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin")))
  end

  include_context "app"

  let :autorun do
    false
  end

  it "reports the failure" do
    expect {
      Pakyow.app :test_foo do
        plug :foo, at: "/"
      end
    }.to raise_error(Pakyow::UnknownPlugin) do |error|
      expect(error.message).to eq("`foo' is not a known plugin")
      expect(error.contextual_message).to eq(
        <<~MESSAGE
          Try using one of these available plugins:

            - :testable

        MESSAGE
      )
    end
  end
end
