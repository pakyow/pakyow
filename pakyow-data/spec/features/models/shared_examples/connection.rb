RSpec.shared_examples :model_connection do
  describe "connecting a model" do
    let :connection do
      Pakyow.apps.first.data.posts.source.model.connection
    end

    context "single default connection is defined" do
      before do
        Pakyow.config.connections.sql[:default] = "sqlite://"
      end

      include_context "testable app"

      context "model does not specify connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection).to eq(:default)
        end
      end

      context "model specifies the default connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts, connection: :default do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection).to eq(:default)
        end
      end
    end

    context "single non-default connection is defined" do
      before do
        Pakyow.config.connections.sql[:test] = "sqlite://"
      end

      include_context "testable app"

      context "model specifies a connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts, connection: :test do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection).to eq(:test)
        end
      end
    end

    context "multiple connections are defined, with a default" do
      before do
        Pakyow.config.connections.sql[:default] = "sqlite://"
        Pakyow.config.connections.sql[:test] = "sqlite://"
      end

      include_context "testable app"

      context "model does not specify connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection).to eq(:default)
        end
      end

      context "model specifies the default connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts, connection: :default do
              primary_id
            end
          end
        end

        it "connects to the default connection" do
          expect(connection).to eq(:default)
        end
      end

      context "model specifies a connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts, connection: :test do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection).to eq(:test)
        end
      end
    end

    context "multiple connections are defined, with no default" do
      before do
        Pakyow.config.connections.sql[:test1] = "sqlite://"
        Pakyow.config.connections.sql[:test2] = "sqlite://"
      end

      include_context "testable app"

      context "model specifies a connection" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :posts, connection: :test2 do
              primary_id
            end
          end
        end

        it "connects to the specified connection" do
          expect(connection).to eq(:test2)
        end
      end
    end
  end
end
