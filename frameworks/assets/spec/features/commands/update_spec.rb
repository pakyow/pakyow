RSpec.describe "cli: assets:update" do
  include_context "app"
  include_context "command"

  let(:command) {
    "assets:update"
  }

  let(:app_def) {
    Proc.new {
      external_script :jquery
    }
  }

  before do
    Pakyow.app(:test).config.assets.externals.scripts.each do |script|
      allow(script).to receive(:fetch!)
    end
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/update/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "fetches each external script" do
      Pakyow.app(:test).config.assets.externals.scripts.each do |script|
        expect(script).to receive(:fetch!)
      end

      run_command(command, project: true)
    end

    describe "fetching an asset" do
      it "fetches the corresponding script" do
        expect(Pakyow.app(:test).config.assets.externals.scripts.find { |script|
          script.name == :jquery
        }).to receive(:fetch!)

        run_command(command, asset: "jquery", project: true)
      end

      it "does not fetch other scripts" do
        expect(Pakyow.app(:test).config.assets.externals.scripts.find { |script|
          script.name == :pakyow
        }).not_to receive(:fetch!)

        run_command(command, asset: "jquery", project: true)
      end

      context "asset cannot be found" do
        it "raises an error" do
          expect {
            run_command(command, asset: "unknown", project: true, tty: false)
          }.to raise_error(Pakyow::Assets::UnknownExternalAsset)
        end
      end
    end
  end
end
