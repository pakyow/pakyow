RSpec.describe "auto migrating on boot" do
  before do
    require "pakyow/data/migrator"
    Pakyow.config.data.connections.send(adapter_type)[:default] = adapter_url
    Pakyow.config.data.auto_migrate = auto_migrate_enabled
    Pakyow.config.data.auto_migrate_always = auto_migrate_always
    setup_gateway_expectations
  end

  let :auto_migrate_always do
    []
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
        "sqlite::memory"
      end

      def setup_gateway_expectations
        expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
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
      "sqlite::memory"
    end

    def setup_gateway_expectations
      expect_any_instance_of(Pakyow::Data::Migrator).to_not receive(:auto_migrate!)
    end

    it "does not auto migrate" do
      # intentionally empty
    end

    context "connection is set to always migrate" do
      let :auto_migrate_always do
        [:default]
      end

      def setup_gateway_expectations
        expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
      end
    end
  end
end

RSpec.describe "auto migrating" do
  it "needs to be defined"
end
