RSpec.describe "auto migrating on boot" do
  before do
    require "pakyow/data/migrator"
    Pakyow.config.data.connections.send(adapter_type)[:default] = adapter_url
    Pakyow.config.data.auto_migrate = auto_migrate_enabled
    Pakyow.config.data.auto_migrate_always = auto_migrate_always
    setup_expectations
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

      def setup_expectations
        expect_any_instance_of(Pakyow::Data::Migrator).to receive(:auto_migrate!)
      end

      it "auto migrates" do
        # intentionally empty
      end

      describe "migrating the source for a connection" do
        let :app_definition do
          Proc.new {
            source :posts do
              primary_id
            end
          }
        end

        def setup_expectations
          expect_any_instance_of(Pakyow::Data::Connection).to receive(:auto_migrate!) { |_, source|
            expect(source).to be(Test::Sources::Posts)
          }
        end

        it "auto migrates" do
          # intentionally empty
        end

        context "app is rescued" do
          let :app_definition do
            Proc.new {
              source :posts do
                primary_id
              end

              before :initialize do
                @rescued = true
              end
            }
          end

          def setup_expectations
            expect_any_instance_of(Pakyow::Data::Connection).not_to receive(:auto_migrate!)
          end

          it "does not auto migrate" do
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

RSpec.describe "auto migrating" do
  it "needs to be defined"
end
