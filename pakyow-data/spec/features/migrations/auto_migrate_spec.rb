require "rom/memory"
require "rom/sql"

RSpec.describe "auto migrating on boot" do
  before do
    Pakyow.config.connections.send(adapter_type)[:default] = adapter_url
    Pakyow.config.data.auto_migrate = auto_migrate_enabled
    setup_gateway_expectations
  end

  include_context "testable app"

  context "auto migration is enabled" do
    let :auto_migrate_enabled do
      true
    end

    context "using an adapter that supports auto migration" do
      let :adapter_type do
        :sql
      end

      let :adapter_url do
        "sqlite://"
      end

      def setup_gateway_expectations
        expect_any_instance_of(ROM::SQL::Gateway).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
      end
    end

    context "using an adapter that does not support auto migration" do
      let :adapter_type do
        :memory
      end

      let :adapter_url do
        "memory://test"
      end

      def setup_gateway_expectations
        # intentionally empty
      end

      it "does not attempt to auto migrate" do
        # intentionally empty; this will fail if auto migrate is called
      end
    end
  end

  context "auto migration is disabled" do
    let :auto_migrate_enabled do
      false
    end

    let :adapter_type do
      :sql
    end

    let :adapter_url do
      "sqlite://"
    end

    def setup_gateway_expectations
      expect_any_instance_of(ROM::SQL::Gateway).to_not receive(:auto_migrate!)
    end

    it "does not auto migrate" do
      # intentionally empty
    end
  end
end

require_relative "shared_examples/auto_migration"

RSpec.describe "auto migrating in sqlite" do
  include_examples :auto_migration
end

RSpec.describe "auto migrating in postgres" do
  include_examples :auto_migration
end

RSpec.describe "auto migrating in mysql" do
  include_examples :auto_migration
end
