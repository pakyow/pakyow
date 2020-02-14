require "pakyow/cli"

RSpec.describe "cli: prelaunch" do
  include_context "app"
  include_context "command"

  let :command do
    "prelaunch"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true, tty: false)).to eq("\e[34;1mRun the prelaunch commands\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow prelaunch\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    let(:calls) {
      []
    }

    let(:ivars) {
      {}
    }

    context "prelaunch commands are defined for the environment" do
      before do
        local = self

        Pakyow.config.commands.prelaunch << :foo
        Pakyow.config.commands.prelaunch << :baz

        Pakyow.command :foo do
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
          required :cli

          action do
            local.calls << :baz
          end
        end
      end

      it "runs each command with the defined options" do
        run_command(command, project: true, tty: false)

        expect(calls).to eq([:foo, :baz])
      end

      it "adds the cli as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:foo][:@cli]).to be_instance_of(Pakyow::CLI)
      end
    end

    context "prelaunch commands are defined for an application" do
      let(:app_def) {
        local = self

        Proc.new {
          Pakyow.command :app_foo do
            required :cli
            required :app

            action do
              local.calls << :app_foo
              local.ivars[:app_foo] = instance_variables.each_with_object({}) { |ivar, ivars|
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
            required :cli
            required :app

            action do
              local.calls << :app_baz
            end
          end

          configure do
            config.commands.prelaunch << :app_foo
            config.commands.prelaunch << :app_baz
          end
        }
      }

      it "runs each command with the defined options" do
        run_command(command, project: true, tty: false)

        expect(calls).to eq([:app_foo, :app_baz])
      end

      it "adds the cli as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:app_foo][:@cli]).to be_instance_of(Pakyow::CLI)
      end

      it "adds the app as an option" do
        run_command(command, project: true, tty: false)

        expect(ivars[:app_foo][:@app]).to be_instance_of(app)
      end
    end

    context "prelaunch command does not exist" do
      before do
        Pakyow.config.commands.prelaunch << :unknown
      end

      it "errors" do
        expect {
          run_command(command, project: true, tty: false)
        }.to raise_error(Pakyow::UnknownCommand) do |error|
          expect(error.message).to eq("`unknown' is not a known command")
        end
      end
    end

    context "prelaunch command errors" do
      before do
        local = self

        Pakyow.config.commands.prelaunch << :foo
        Pakyow.config.commands.prelaunch << :bar

        Pakyow.command :foo do
          action do
            fail
          end
        end

        Pakyow.command :bar do
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

    describe "running defined tasks" do
      before do
        local = self

        Pakyow.config.tasks.prelaunch << :foo

        Pakyow.command :foo do
          action do
            local.calls << :foo
          end
        end
      end

      let(:app_def) {
        local = self

        Proc.new {
          configure do
            config.tasks.prelaunch << :app_foo
          end

          Pakyow.command :app_foo do
            action do
              local.calls << :app_foo
            end
          end
        }
      }

      it "runs prelaunch tasks defined for the environment" do
        run_command(command, project: true, tty: false)

        expect(calls).to include(:foo)
      end

      it "runs prelaunch tasks defined for an application" do
        run_command(command, project: true, tty: false)

        expect(calls).to include(:app_foo)
      end
    end
  end
end
