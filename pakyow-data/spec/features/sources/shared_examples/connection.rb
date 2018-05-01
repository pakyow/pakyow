RSpec.shared_examples :source_connection do
  describe "connecting a source" do
    let :connection do
      Pakyow.apps.first.data.posts.source.container.connection
    end

    context "single default connection is defined" do
      before do
        Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
      end

      include_context "testable app"

      context "source does not specify connection" do
        let :app_definition do
          Proc.new do
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
          Proc.new do
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
      before do
        Pakyow.config.data.connections.public_send(connection_type)[:test] = connection_string
      end

      include_context "testable app"

      context "source specifies a connection" do
        let :app_definition do
          Proc.new do
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
      before do
        Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
        Pakyow.config.data.connections.public_send(connection_type)[:test] = connection_string
      end

      include_context "testable app"

      context "source does not specify connection" do
        let :app_definition do
          Proc.new do
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
          Proc.new do
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
          Proc.new do
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
      before do
        Pakyow.config.data.connections.public_send(connection_type)[:test1] = connection_string
        Pakyow.config.data.connections.public_send(connection_type)[:test2] = connection_string
      end

      include_context "testable app"

      context "source specifies a connection" do
        let :app_definition do
          Proc.new do
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
