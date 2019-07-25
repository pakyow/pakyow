require "pakyow/cli"
require "pakyow/generator"

require_relative "./shared/default_structure"

RSpec.describe "cli: creating the example project" do
  include_context "command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(false)
    allow(Bundler).to receive(:with_clean_env)
  end

  let :command do
    "create"
  end

  describe "generated project" do
    let :generated_path do
      File.join(command_dir, path)
    end

    let :path do
      "test/app-test"
    end

    before do
      unless File.exist?(generated_path)
        run_command(command, path, "-t example", cleanup: false)
      end
    end

    after "all" do
      cleanup_after_command
    end

    include_examples :default_structure

    describe "frontend" do
      describe "assets" do
        describe "styles" do
          it "contains base and themes" do
            expect(Dir.glob(File.join(generated_path, "frontend/assets/styles/*")).sort).to eq([
              File.join(generated_path, "frontend/assets/styles/base"),
              File.join(generated_path, "frontend/assets/styles/themes")
            ])
          end
        end
      end

      describe "layouts" do
        it "contains default styles" do
          expect(Dir.glob(File.join(generated_path, "frontend/layouts/*"))).to include(
            File.join(generated_path, "frontend/layouts/default.scss")
          )
        end
      end
    end
  end
end
