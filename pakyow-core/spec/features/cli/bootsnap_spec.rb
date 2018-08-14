require "fileutils"
require "bootsnap"

require "pakyow/cli"

RSpec.describe "using bootsnap in the cli" do
  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:load_environment)
    allow_any_instance_of(Pakyow::CLI).to receive(:load_tasks)
    allow_any_instance_of(Pakyow::CLI).to receive(:puts_help)
    allow_any_instance_of(Pakyow::CLI).to receive(:puts_error)
  end

  after do
    if File.exist?(cache_dir)
      FileUtils.rm_r(cache_dir)
    end
  end

  let :cache_dir do
    File.join(Dir.pwd, "tmp/cache")
  end

  context "within a project folder" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
    end

    context "bootsnap is available" do
      before do
        expect(defined?(Bootsnap)).to eq("constant")
      end

      context "environment is development" do
        it "sets up bootsnap in development mode" do
          expect(Bootsnap).to receive(:setup).with({
            cache_dir:            cache_dir,
            development_mode:     true,
            load_path_cache:      true,
            autoload_paths_cache: false,
            disable_trace:        false,
            compile_cache_iseq:   true,
            compile_cache_yaml:   true
          })

          Pakyow::CLI.new(["--env=development"])
        end

        it "sets up bootsnap, but not in development mode" do
          expect(Bootsnap).to receive(:setup).with({
            cache_dir:            cache_dir,
            development_mode:     false,
            load_path_cache:      true,
            autoload_paths_cache: false,
            disable_trace:        false,
            compile_cache_iseq:   true,
            compile_cache_yaml:   true
          })

          Pakyow::CLI.new(["--env=production"])
        end
      end
    end

    context "bootsnap is not available" do
      before do
        allow_any_instance_of(Pakyow::CLI).to receive(:require) do |_, arg|
          if arg == "bootsnap"
            raise LoadError
          end
        end
      end

      it "does not try to setup bootsnap" do
        expect(Bootsnap).to_not receive(:setup)
        Pakyow::CLI.new
      end
    end
  end

  context "outside of a project folder" do
    before do
      allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(false)
    end

    context "bootsnap is available" do
      before do
        expect(defined?(Bootsnap)).to eq("constant")
      end

      it "does not try to setup bootsnap" do
        expect(Bootsnap).to_not receive(:setup)
        Pakyow::CLI.new
      end
    end
  end
end
