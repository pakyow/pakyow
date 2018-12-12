RSpec.shared_examples :source_connection do
  describe "connecting a source" do
    let :connection do
      Pakyow.apps.first.data.posts.source.class.container.connection
    end

    context "single default connection is defined" do
      include_context "testable app"

      context "source does not specify connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection.name).to eq(:default)
        end
      end

      context "source specifies the default connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts, connection: :default do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection.name).to eq(:default)
        end
      end
    end

    context "single non-default connection is defined" do
      include_context "testable app"

      context "source specifies a connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:test] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts, connection: :test do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection.name).to eq(:test)
        end
      end
    end

    context "multiple connections are defined, with a default" do
      include_context "testable app"

      context "source does not specify connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
              config.data.connections.public_send(local_connection_type)[:test] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection.name).to eq(:default)
        end
      end

      context "source specifies the default connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
              config.data.connections.public_send(local_connection_type)[:test] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts, connection: :default do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection.name).to eq(:default)
        end
      end

      context "source specifies a connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
              config.data.connections.public_send(local_connection_type)[:test] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts, connection: :test do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection.name).to eq(:test)
        end
      end
    end

    context "multiple connections are defined, with no default" do
      include_context "testable app"

      context "source specifies a connection" do
        let :app_definition do
          local_connection_type, local_connection_string = connection_type, connection_string

          Proc.new do
            Pakyow.after :configure do
              config.data.connections.public_send(local_connection_type)[:test1] = local_connection_string
              config.data.connections.public_send(local_connection_type)[:test2] = local_connection_string
            end

            instance_exec(&$data_app_boilerplate)

            source :posts, connection: :test2 do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection.name).to eq(:test2)
        end
      end
    end
  end
end
