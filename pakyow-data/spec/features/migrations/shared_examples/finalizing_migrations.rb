RSpec.shared_examples :finalizing_migrations do
  describe "finalizing migrations" do
    # We test this by defining a source that contains two tables, with an existing
    # migration for only the first migration. If finalization is working properly
    # we'll generate a second migration for the second table.

    before do
      Pakyow.config.data.connections.sql[:default] = connection_string
      Pakyow.config.data.migration_path = "./spec/features/migrations/support/database/migrations"
      Pakyow.load_tasks

      # Create the initial migration.
      #
      FileUtils.mkdir_p(adapter_migration_path)
      File.open(File.join(adapter_migration_path, "20180418165207000_create_posts.rb"), "w+") do |file|
        file.write(initial_migration_content)
      end
    end

    after do
      FileUtils.rm_r(adapter_migration_path)
    end

    def adapter_migration_path
      File.join(Pakyow.config.data.migration_path, "sql", "default")
    end

    def migrations
      Dir.glob(File.join(adapter_migration_path, "*.rb"))
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :post do
          primary_id
          attribute :title
        end

        source :comment do
          primary_id
          attribute :title
        end
      end
    end

    it "creates a migration for each finalized change" do
      expect(migrations.count).to eq(1)
      Rake::Task["db:finalize"].reenable
      Rake::Task["db:finalize"].invoke("sql", "default")
      expect(migrations.count).to eq(2)
      expect(migrations[1]).to include("create_comments")
      expect(File.read(migrations[1])).to eq(finalized_migration_content)
    end
  end
end
