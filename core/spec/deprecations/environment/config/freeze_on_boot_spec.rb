RSpec.describe "Pakyow.config.freeze_on_boot deprecation" do
  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with("Pakyow.config.freeze_on_boot", solution: "do not use")

    Pakyow.config.freeze_on_boot
  end
end
