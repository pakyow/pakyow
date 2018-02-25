RSpec.describe "missing asset pack warning" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
      config.assets.autoloaded_packs = [:nonexistent]
    end
  end

  it "logs a warning" do
    expect_any_instance_of(Pakyow::Logger::RequestLogger).to receive(:warn) do |_, message|
      expect(message).to eq("Could not find pack `nonexistent'")
    end

    call("/packs/autoload")
  end
end
