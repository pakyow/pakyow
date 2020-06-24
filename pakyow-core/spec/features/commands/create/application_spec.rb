require "pakyow/cli"

require_relative "../create/shared/default_structure"

RSpec.describe "cli: create:application" do
  include_context "command"

  before do
    allow(Bundler).to receive(:with_original_env)
  end

  let(:command) {
    "create:application"
  }

  describe "help" do
    before do
      Pakyow.load(env: :test)
    end

    it "is helpful" do
      cached_expectation "commands/create/application/help" do
        run_command(command, project: true, help: true)
      end
    end
  end

  describe "running" do
    let(:application_name) {
      "foo"
    }

    let(:application_path) {
      "apps/foo"
    }

    context "default application exists" do
      before do
        run_command("create", path: command_dir, cleanup: false) do
          expect(File.exist?(File.join(command_dir, "config/environment.rb"))).to be(true)

          Pakyow.setup(env: :test)
        end
      end

      it "relocates the default application" do
        expect(File.exist?(File.join(command_dir, "apps/tmp"))).to be(false)

        run_command(command, project: true, name: application_name) do
          expect(File.exist?(File.join(command_dir, "apps/tmp"))).to be(true)
        end
      end

      it "creates an application with the given name" do
        expect(File.exist?(File.join(command_dir, application_path))).to be(false)

        run_command(command, project: true, name: application_name) do
          expect(File.exist?(File.join(command_dir, application_path))).to be(true)
        end
      end

      it "updates external assets" do
        expect_any_instance_of(Pakyow::Generators::Application).to receive(:run).at_least(:once).with(
          "bundle exec pakyow assets:update -a foo",
          message: "Updating external assets"
        )

        allow(Bundler).to receive(:with_original_env) do |&block|
          block.call
        end

        run_command(command, project: true, name: application_name)
      end
    end

    context "default application does not exist" do
      it "does not relocate the default application" do
        expect(File.exist?(File.join(command_dir, "apps/tmp"))).to be(false)

        run_command(command, project: true, name: application_name) do
          expect(File.exist?(File.join(command_dir, "apps/tmp"))).to be(false)
        end
      end

      it "creates an application with the given name" do
        expect(File.exist?(File.join(command_dir, application_path))).to be(false)

        run_command(command, project: true, name: application_name) do
          expect(File.exist?(File.join(command_dir, application_path))).to be(true)
        end
      end
    end

    describe "generated application" do
      before do
        run_command("create", path: command_dir, cleanup: false) do
          expect(File.exist?(File.join(command_dir, "config/environment.rb"))).to be(true)

          Pakyow.setup(env: :test)

          run_command(command, project: true, name: application_name, cleanup: false)
        end
      end

      after do
        cleanup_after_command
      end

      include_examples :default_application_structure do
        let(:generated_path) do
          File.join(command_dir, "apps/foo")
        end

        let(:app_name) {
          :foo
        }
      end
    end
  end
end
