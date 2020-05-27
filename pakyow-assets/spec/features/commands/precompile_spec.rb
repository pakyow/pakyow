require "pakyow/cli"

RSpec.describe "cli: assets:precompile" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "assets:precompile"
  }

  before do
    require "pakyow/assets/precompiler"
    allow(Pakyow::Assets::Precompiler).to receive(:new).and_return(precompiler_instance)
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/precompile/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "initializes the precompiler" do
      expect(Pakyow::Assets::Precompiler).to receive(:new).with(app).and_return(precompiler_instance)

      run_command(command, project: true)
    end

    it "invokes the precompiler" do
      expect(precompiler_instance).to receive(:precompile!)

      run_command(command, project: true)
    end
  end
end
