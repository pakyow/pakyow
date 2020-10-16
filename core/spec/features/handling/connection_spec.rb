RSpec.describe "handling events during a request lifecycle with connection handlers" do
  include_context "app"

  let(:global_handlers_def) {
    Proc.new {
      Pakyow.handle :foo do |connection:|
        connection.body.write "foo_environment"
      end

      handle :foo do |connection:|
        connection.body.write "foo_application"
      end
    }
  }

  context "connection defines a matching handler" do
    let(:handlers_def) {
      local = self

      Proc.new {
        instance_eval(&local.global_handlers_def)

        action do |connection|
          connection.handle :foo do
            connection.body.write "foo_connection"
          end
        end
      }
    }

    context "event is triggered on the environment" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.handlers_def)

          action do |connection|
            Pakyow.trigger :foo, connection: connection
          end
        }
      }

      it "handles the event in the environment" do
        expect(call("/")[2]).to eq("foo_environment")
      end
    end

    context "event is triggered on the application" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.handlers_def)

          action do |connection|
            trigger :foo, connection: connection
          end
        }
      }

      it "handles the event in the application" do
        expect(call("/")[2]).to eq("foo_application")
      end
    end

    context "event is triggered on the connection" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.handlers_def)

          action do |connection|
            connection.trigger :foo
          end
        }
      }

      it "handles the event in the connection" do
        expect(call("/")[2]).to eq("foo_connection")
      end
    end
  end

  context "connection does not define a matching handler" do
    let(:handlers_def) {
      local = self

      Proc.new {
        instance_eval(&local.global_handlers_def)
      }
    }

    context "event is triggered in the environment connection" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.handlers_def)

          Pakyow.action do |connection|
            connection.trigger :foo
          end
        }
      }

      it "handles the event in the environment" do
        expect(call("/")[2]).to eq("foo_environment")
      end
    end

    context "event is triggered in the application connection" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.handlers_def)

          action do |connection|
            connection.trigger :foo
          end
        }
      }

      it "handles the event in the application" do
        expect(call("/")[2]).to eq("foo_application")
      end
    end
  end

  context "event is an error" do
    let(:allow_request_failures) {
      true
    }

    let(:global_handlers_def) {
      Proc.new {
        Pakyow.handle RuntimeError do |connection:|
          connection.body.write "foo_environment"
        end

        handle RuntimeError do |connection:|
          connection.body.write "foo_application"
        end
      }
    }

    context "error occurs in the environment" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.global_handlers_def)

          Pakyow.action do |connection|
            fail
          end
        }
      }

      it "handles the event in the environment" do
        expect(call("/")[2]).to eq("foo_environment")
      end
    end

    context "error occurs in the application" do
      let(:app_def) {
        local = self

        Proc.new {
          instance_eval(&local.global_handlers_def)

          action do |connection|
            fail
          end
        }
      }

      it "handles the event in the application" do
        expect(call("/")[2]).to eq("foo_application")
      end
    end

    context "environment connection defines a matching handler" do
      let(:handlers_def) {
        local = self

        Proc.new {
          instance_eval(&local.global_handlers_def)

          Pakyow.action do |connection|
            connection.handle RuntimeError do
              connection.body.write "foo_environment_connection"
            end
          end
        }
      }

      context "error occurs in the environment" do
        let(:app_def) {
          local = self

          Proc.new {
            instance_eval(&local.handlers_def)

            Pakyow.action do |connection|
              fail
            end
          }
        }

        it "handles the event in the environment connection" do
          expect(call("/")[2]).to eq("foo_environment_connection")
        end
      end

      context "error occurs in the application" do
        let(:app_def) {
          local = self

          Proc.new {
            instance_eval(&local.handlers_def)

            action do |connection|
              fail
            end
          }
        }

        it "handles the event in the application" do
          expect(call("/")[2]).to eq("foo_application")
        end
      end
    end

    context "application connection defines a matching handler" do
      let(:handlers_def) {
        local = self

        Proc.new {
          instance_eval(&local.global_handlers_def)

          action do |connection|
            connection.handle RuntimeError do
              connection.body.write "foo_application_connection"
            end
          end
        }
      }

      context "error occurs in the environment" do
        let(:app_def) {
          local = self

          Proc.new {
            instance_eval(&local.handlers_def)

            Pakyow.action do |connection|
              fail
            end
          }
        }

        it "handles the event in the environment" do
          expect(call("/")[2]).to eq("foo_environment")
        end
      end

      context "error occurs in the application" do
        let(:app_def) {
          local = self

          Proc.new {
            instance_eval(&local.handlers_def)

            action do |connection|
              fail
            end
          }
        }

        it "handles the event in the application connection" do
          expect(call("/")[2]).to eq("foo_application_connection")
        end
      end
    end
  end
end
