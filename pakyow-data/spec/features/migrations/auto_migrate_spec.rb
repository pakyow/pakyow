RSpec.describe "auto migrating on boot" do
  before do
    require "pakyow/data/migrator"

    Pakyow.config.data.auto_migrate = auto_migrate_enabled
    Pakyow.config.data.auto_migrate_always = auto_migrate_always

    local_adapter_type, local_adapter_url = adapter_type, adapter_url

    Pakyow.after "configure" do
      Pakyow.config.data.connections.send(local_adapter_type)[:default] = local_adapter_url
      Pakyow.config.data.connections.send(local_adapter_type).delete(:memory)
    end

    setup_expectations
  end

  let :auto_migrate_always do
    []
  end

  include_context "app"

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

      def setup_expectations
        expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
      end

      describe "auto migrating sources for the connection" do
        let :app_def do
          Proc.new do
            source :posts do
              primary_id
            end
          end
        end

        def setup_expectations
          expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!) { |migrator|
            expect(migrator.send(:sources)).to eq([Test::Sources::Posts])
          }
        end

        it "auto migrates" do
          # intentionally empty
        end

        context "app is rescued" do
          let :app_def do
            Proc.new do
              before "initialize" do
                @error = true
              end

              source :posts do
              end
            end
          end

          def setup_expectations
            expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!) { |migrator|
              expect(migrator.send(:sources)).to eq([])
            }
          end

          let :allow_application_rescues do
            true
          end

          it "does not auto migrate that app's sources" do
            # intentionally empty
          end
        end
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

    def setup_expectations
      expect_any_instance_of(Pakyow::Data::Migrator).to_not receive(:auto_migrate!)
    end

    it "does not auto migrate" do
      # intentionally empty
    end

    context "connection is set to always migrate" do
      let :auto_migrate_always do
        [:default]
      end

      def setup_expectations
        expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
      end
    end
  end
end
