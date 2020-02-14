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
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mPrecompile assets\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow assets:precompile\n\n\e[1mOPTIONS\e[0m\n  -a, --app=app  \e[33mThe app to run the command on\e[0m\n  -e, --env=env  \e[33mThe environment to run this command under\e[0m\n")
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
