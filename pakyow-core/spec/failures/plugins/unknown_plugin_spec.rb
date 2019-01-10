require "pakyow/plugin"

RSpec.describe "failure caused by plugging an unknown plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)

    Foo.constants(false).each do |const_to_unset|
      Foo.__send__(:remove_const, const_to_unset)
    end

    Object.__send__(:remove_const, :Foo)
  end

  include_context "app"

  let :autorun do
    false
  end

  it "reports the failure" do
    expect {
      Pakyow.app :foo do
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
