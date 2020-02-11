require "pakyow/cli"

RSpec.describe "command line interface" do
  shared_examples :banner do
    it "prints the banner" do
      expect(output).to include("\e[34;1mPakyow Command Line Interface\e[0m\n")
    end
  end

  shared_examples :without_banner do
    it "does not print the banner" do
      expect(output).to_not include("\e[34;1mPakyow Command Line Interface\e[0m\n")
    end
  end

  shared_examples :help do
    it "prints usage instructions" do
      expect(output).to include("\e[1mUSAGE\e[0m\n")
      expect(output).to include("  $ pakyow [COMMAND]\n")
    end

    it "prints known commands" do
      expect(output).to include("\e[1mCOMMANDS\e[0m\n")
      expect(output).to include("  boot                   \e[33mBoot the project\e[0m\n")
      expect(output).to include("  help                   \e[33mGet help for the command line interface\e[0m\n")
      expect(output).to include("  prelaunch              \e[33mRun the prelaunch commands\e[0m\n")
      expect(output).to include("  info                   \e[33mShow details about the current project\e[0m\n")
      expect(output).to include("  irb                    \e[33mStart an interactive session\e[0m\n")
      expect(output).to include("  test:pass_app          \e[33mTest passing the application\e[0m\n")
      expect(output).to include("  test:pass_arg_opt_flg  \e[33mTest arguments + options\e[0m\n")
      expect(output).to include("  test:pass_env          \e[33mTest passing the environment\e[0m\n")
    end
  end

  shared_examples :help_with_banner do
    include_examples :banner
    include_examples :help
  end

  shared_examples :help_without_banner do
    include_examples :without_banner
    include_examples :help
  end

  shared_examples :command_help do
    let :command do
      "test:pass_arg_opt_flg"
    end

    it "prints usage instructions" do
      expect(output).to include("\e[1mUSAGE\e[0m\n")
      expect(output).to include("  $ pakyow test:pass_arg_opt_flg [FOO] --baz=baz\n")
    end

    it "prints arguments" do
      expect(output).to include("\e[1mARGUMENTS\e[0m\n")
      expect(output).to include("  FOO  \e[33mFoo arg\e[0m\e[31m (required)\e[0m\n")
      expect(output).to include("  BAR  \e[33mBar arg\e[0m\n")
    end

    it "prints options" do
      expect(output).to include("\e[1mOPTIONS\e[0m\n")
      expect(output).to include("  -b, --baz=baz  \e[33mBaz arg\e[0m\e[31m (required)\e[0m\n")
      expect(output).to include("  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
      expect(output).to include("  -q, --qux=qux  \e[33mQux arg (default: qux)\e[0m\n")
    end

    it "prints flags" do
      expect(output).to include("      --meh      \e[33mMeh flag\e[0m\n")
    end
  end

  shared_examples :command_banner do
    it "prints the command banner" do
      expect(output).to include("\e[34;1mTest arguments + options\e[0m\n")
    end
  end

  shared_examples :without_command_banner do
    it "does not print the command banner" do
      expect(output).to_not include("\e[34;1mTest arguments + options\e[0m\n")
    end
  end

  shared_examples :command_help_with_banner do
    include_examples :command_help
    include_examples :command_banner
  end

  shared_examples :command_help_without_banner do
    include_examples :command_help
    include_examples :without_command_banner
  end

  shared_examples :env do
    let :command do
      "test:pass_env"
    end

    let :argv do
      [arg, env]
    end

    it "sets the environment" do
      expect(output).to include("Pakyow.env: #{env}")
    end

    it "sets APP_ENV" do
      expect(ENV["APP_ENV"]).to eq(env)
    end

    it "sets RACK_ENV" do
      expect(ENV["RACK_ENV"]).to eq(env)
    end
  end

  shared_examples :app do
    context "command accepts the app" do
      let :command do
        "test:pass_app"
      end

      let :argv do
        [arg, "test"]
      end

      context "app is found" do
        it "passes the app to the command" do
          expect(output).to include("args[:app]: test")
        end

        context "environment is specified" do
          let :argv do
            [arg, "test", "--env=testenv"]
          end

          it "sets up the app in the specified environment" do
            expect(output).to include("args[:app]: test (testenv)")
          end
        end
      end

      context "app is not found" do
        let :argv do
          [arg, "unknown"]
        end

        it "prints an error" do
          expect(output).to include("  \e[31m›\e[0m \e[3;34munknown\e[0m is not a known app\n")
        end
      end

      context "multiple apps exist" do
        def define_apps
          Pakyow.app :test1, path: "/test1"
          Pakyow.app :test2, path: "/test2"
        end

        context "app is unspecified" do
          let :argv do
            []
          end

          it "prints an error" do
            expect(output).to include("  \e[31m›\e[0m multiple apps were found; please specify one with the --app option\n")
          end
        end
      end

      context "no apps exist" do
        def define_apps
          # intentionally empty
        end

        context "app is unspecified" do
          let :argv do
            []
          end

          it "prints an error" do
            expect(output).to include("  \e[31m›\e[0m couldn't find an app to run this command for\n")
          end
        end
      end
    end

    context "command does not accept the app" do
      let :command do
        "test:pass_env"
      end

      let :argv do
        [arg, "test"]
      end

      it "runs the command" do
        expect(output).to include("Pakyow.env")
      end

      it "prints a warning" do
        expect(output).to include("  \e[33m›\e[0m app was ignored by command \e[34mtest:pass_env\e[0m\n")
      end
    end
  end

  before do
    define_apps

    allow(Pakyow::CLI).to receive(:project_context?).and_return(project_context)

    # Set the working directory to the supporting app.
    #
    original_pwd = Dir.pwd
    Dir.chdir(File.expand_path("../support", __FILE__))

    # Run the command, capturing output.
    #
    output = StringIO.new
    allow(output).to receive(:tty?).and_return(true)
    Pakyow::CLI.run([command].concat(argv).compact, output: output)
    output.rewind
    @output = output.read

    # Set the working directory back to the original value.
    #
    Dir.chdir(original_pwd)
  end

  after do
    Pakyow.mounts.clear

    cache_dir = File.expand_path("../support/tmp/cache", __FILE__)
    if File.exist?(cache_dir)
      FileUtils.rm_r(cache_dir)
    end
  end

  let :output do
    @output
  end

  let :command do
    nil
  end

  let :argv do
    []
  end

  let :project_context do
    true
  end

  def define_apps
    Pakyow.app :test
  end

  context "running without a command" do
    include_examples :help_with_banner

    context "passing -h" do
      include_examples :help_with_banner
    end

    context "passing --help" do
      include_examples :help_with_banner
    end
  end

  context "running a known command" do
    context "passing -e" do
      let :arg do
        "-e"
      end

      let :env do
        "testing"
      end

      include_examples :env
    end

    context "passing --env" do
      let :arg do
        "--env"
      end

      let :env do
        "testing"
      end

      include_examples :env
    end

    context "passing -a" do
      let :arg do
        "-a"
      end

      include_examples :app
    end

    context "passing --app" do
      let :arg do
        "--app"
      end

      include_examples :app
    end

    context "passing -h" do
      let :argv do
        ["-h"]
      end

      include_examples :command_help_with_banner
    end

    context "passing --help" do
      let :argv do
        ["--help"]
      end

      include_examples :command_help_with_banner
    end

    context "missing a required argument" do
      let :command do
        "test:pass_arg_opt_flg"
      end

      let :argv do
        ["--baz=baz_value"]
      end

      it "prints an error" do
        expect(output).to include("  \e[31m›\e[0m \e[3;34mfoo\e[0m is a required argument\n")
      end

      include_examples :command_help_without_banner
    end

    context "missing a required option" do
      let :command do
        "test:pass_arg_opt_flg"
      end

      let :argv do
        ["foo_value"]
      end

      it "prints an error" do
        expect(output).to include("  \e[31m›\e[0m \e[3;34mbaz\e[0m is a required option\n")
      end

      include_examples :command_help_without_banner
    end

    context "passing an unknown argument" do
      let :command do
        "test:pass_arg_opt_flg"
      end

      let :argv do
        ["--baz=baz_value", "foo_value", "baz_value", "unknown"]
      end

      it "prints an error" do
        expect(output).to include("  \e[31m›\e[0m \e[3;34munknown\e[0m is not a supported argument\n")
      end

      include_examples :command_help_without_banner
    end

    context "passing an unknown option" do
      let :command do
        "test:pass_arg_opt_flg"
      end

      let :argv do
        ["--baz=baz_value", "foo_value", "bar_value", "--unknown=foo"]
      end

      it "prints an error" do
        expect(output).to include("  \e[31m›\e[0m \e[3;34m--unknown=foo\e[0m is not a supported option\n")
      end

      include_examples :command_help_without_banner
    end
  end

  context "running an unknown command" do
    let :command do
      "foo"
    end

    it "prints an error" do
      expect(output).to include("  \e[31m›\e[0m \e[3;34mfoo\e[0m is not a known command\n")
    end

    include_examples :help_without_banner
  end

  context "running a global command within a project context" do
    let :command do
      "create"
    end

    it "prints an error" do
      expect(output).to include("  \e[31m›\e[0m Cannot run command \e[3;34mcreate\e[0m within a pakyow project")
    end

    include_examples :help_without_banner
  end

  context "running a project command within a global context" do
    let :project_context do
      false
    end

    let :command do
      "info"
    end

    it "prints an error" do
      expect(output).to include("  \e[31m›\e[0m Cannot run command \e[3;34minfo\e[0m outside of a pakyow project")
    end
  end
end
