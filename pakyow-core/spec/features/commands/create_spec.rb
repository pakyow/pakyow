require "pakyow/cli"

require_relative "./create/shared/default_structure"

RSpec.describe "cli: create" do
  include_context "command"

  before do
    allow(Bundler).to receive(:with_original_env)

    Pakyow.load(env: :test)
  end

  let :command do
    "create"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/create/help" do
        run_command(command, help: true)
      end
    end
  end

  describe "running" do
    let :path do
      "test/app"
    end

    before do
      allow(Bundler).to receive(:with_original_env)
      allow_any_instance_of(Pakyow::Generators::Project).to receive(:run)
    end

    it "creates a project at the given path" do
      expect(File.exist?(File.join(command_dir, path))).to be(false)

      run_command(command, path: path) do
        expect(File.exist?(File.join(command_dir, path))).to be(true)
      end
    end

    it "runs bundle install" do
      expect_any_instance_of(Pakyow::Generators::Project).to receive(:run).at_least(:once).with(
        "bundle install --binstubs",
        message: "Bundling dependencies"
      )

      allow(Bundler).to receive(:with_original_env) do |&block|
        block.call
      end

      run_command(command, path: path)
    end

    it "updates external assets" do
      expect_any_instance_of(Pakyow::Generators::Project).to receive(:run).at_least(:once).with(
        "bundle exec pakyow assets:update",
        message: "Updating external assets"
      )

      allow(Bundler).to receive(:with_original_env) do |&block|
        block.call
      end

      run_command(command, path: path)
    end

    it "tells the user what to do next" do
      expect(run_command(command, path: path)).to eq("\n\e[1mYou're all set! Go to your new project:\e[0m\n  $ cd test/app\n\n\e[1mThen boot it up:\e[0m\n  $ pakyow boot\n\n")
    end
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
        run_command(command, path: path, cleanup: false)
      end
    end

    after "all" do
      cleanup_after_command
    end

    include_examples :default_structure

    describe "frontend" do
      describe "assets" do
        describe "styles" do
          it "is empty" do
            expect(Dir.glob(File.join(generated_path, "frontend/assets/styles/*"))).to eq([])
          end
        end
      end
    end
  end
end
