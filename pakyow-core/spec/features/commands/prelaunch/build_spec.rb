require "pakyow/cli"

RSpec.describe "cli: prelaunch:build" do
  include_context "app"
  include_context "command"

  let :command do
    "prelaunch:build"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/prelaunch/build/help" do
        run_command(command, help: true, project: true, tty: false)
      end
    end
  end

  describe "running" do
    let(:calls) {
      []
    }

    let(:ivars) {
      {}
    }

    it "sets up the environment" do
      expect(Pakyow).to receive(:setup).with(env: :test)

      run_command(command, project: true, tty: false)
    end

    context "prelaunch commands are defined for the environment" do
      before do
        local = self

        Pakyow.command :foo do
          prelaunch :build

          required :cli

          action do
            local.calls << :foo
            local.ivars[:foo] = instance_variables.each_with_object({}) { |ivar, ivars|
              unless ivar.to_s.start_with?("@__")
                ivars[ivar] = instance_variable_get(ivar)
              end
            }
          end
        end

        Pakyow.command :bar do
          required :cli

          action do
            local.calls << :bar
          end
        end

        Pakyow.command :baz do
          prelaunch :release

          required :cli

          action do
            local.calls << :baz
          end
        end
      end

      it "runs each build phase command with the defined options" do
        run_command(command, project: true, tty: false)

        expect(calls).to eq([:foo])
      end

      it "adds the cli as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:foo][:@cli]).to be_instance_of(Pakyow::CLI)
      end
    end

    context "prelaunch commands are defined for applications" do
      let(:app_def) {
        local = self

        Proc.new {
          Pakyow.app :test_2 do
          end

          Pakyow.command :app_foo do
            prelaunch :build

            required :cli
            required :app

            action do
              local.calls << :app_foo
              (local.ivars[:app_foo] ||= []) << instance_variables.each_with_object({}) { |ivar, ivars|
                unless ivar.to_s.start_with?("@__")
                  ivars[ivar] = instance_variable_get(ivar)
                end
              }
            end
          end

          Pakyow.command :app_bar do
            required :cli
            required :app

            action do
              local.calls << :app_bar
            end
          end

          Pakyow.command :app_baz do
            prelaunch :release

            required :cli
            required :app

            action do
              local.calls << :app_baz
            end
          end
        }
      }

      it "runs each build phase command against each app with the defined options" do
        run_command(command, project: true, tty: false)

        expect(calls).to eq([:app_foo, :app_foo])
      end

      it "adds the cli as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:app_foo].map { |hash| hash[:@cli].class}).to eq([Pakyow::CLI, Pakyow::CLI])
      end

      it "adds the app as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:app_foo].map { |hash| hash[:@app].class}).to eq([Test::Application, Test2::Application])
      end
    end

    context "prelaunch command errors" do
      before do
        local = self

        Pakyow.command :foo, prelaunch: :build do
          action do
            fail
          end
        end

        Pakyow.command :bar, prelaunch: :build do
          action do
            local.calls << :bar
          end
        end
      end

      it "errors" do
        expect {
          run_command(command, project: true, tty: false)
        }.to raise_error
      end

      it "does not run other commands" do
        begin
          run_command(command, project: true, tty: false)
        rescue
        end

        expect(calls).to be_empty
      end
    end

    context "prelaunch command is defined in shorthand" do
      before do
        local = self

        Pakyow.command :foo, prelaunch: :build do
          required :cli

          action do
            local.calls << :foo
          end
        end

        Pakyow.command :bar, prelaunch: :release do
          required :cli

          action do
            local.calls << :bar
          end
        end
      end

      it "runs the command" do
        run_command(command, project: true, tty: false)

        expect(calls).to eq([:foo])
      end
    end
  end
end
