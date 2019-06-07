RSpec.shared_examples :source_logging do
  describe "logging queries" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end

      Pakyow.config.data.silent = !logging_enabled
    end

    include_context "app"

    context "logging is enabled" do
      let :logging_enabled do
        true
      end

      it "configures the logger" do
        expect(Pakyow.data_connections[connection_type][:default].adapter.connection.loggers[0]).to eq(Pakyow.logger)
      end
    end

    context "logging is disabled" do
      let :logging_enabled do
        false
      end

      it "configures the logger" do
        expect(Pakyow.data_connections[connection_type][:default].adapter.connection.loggers[0]).to be(nil)
      end
    end
  end
end
