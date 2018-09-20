require "pakyow/plugin"

RSpec.describe "failure caused by plugging an unknown plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "testable app"

  # let :app_definition do
  #   Proc.new {
  #     plug :foo, at: "/"
  #   }
  # end

  let :autorun do
    false
  end

  it "reports the failure" do
    expect {
      Pakyow.app :foo do
        plug :foo, at: "/"
      end
    }.to raise_error(Pakyow::UnknownPlugin) do |error|
      expect(error.message).to eq(
        <<~MESSAGE
          Pakyow could not find a plugin named `foo`.

          Try using one of these available plugins:

            - :testable

        MESSAGE
      )
    end
  end
end
