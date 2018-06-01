RSpec.shared_examples :source_logging do
  describe "logging queries" do
    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
      Pakyow.config.data.silent = !logging_enabled
    end

    include_context "testable app"

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
