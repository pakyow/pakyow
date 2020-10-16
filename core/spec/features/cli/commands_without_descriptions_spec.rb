RSpec.describe "commands without descriptions" do
  include_context "app"
  include_context "cli"

  before do
    local = self
    Pakyow.command :undescribed, global: true do
      action do
        local.calls << :undescribed
      end
    end

    Pakyow::CLI.run(command, output: output)
    output.rewind
  end

  let(:calls) {
    []
  }

  let(:command) {
    %w(undescribed)
  }

  let(:output) {
    StringIO.new
  }

  context "listing commands" do
    let(:command) {
      %w(--help)
    }

    it "does not include the undescribed command" do
      expect(output.read).not_to include("undescribed")
    end
  end

  context "getting help for the undescribed command" do
    let(:command) {
      %w(undescribed --help)
    }

    it "prints help" do
      expect(output.read).to include("pakyow undescribed")
    end
  end

  context "running the undescribed command" do
    it "can be run" do
      expect(calls).to eq([:undescribed])
    end
  end
end
