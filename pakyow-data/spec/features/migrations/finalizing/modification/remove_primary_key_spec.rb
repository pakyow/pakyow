RSpec.describe "finalizing migration for a removed primary key" do
  let :post_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  let :initial_migration_content do
    {
      "20180503000000_create_posts.rb" => post_migration_content
    }
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          alter_table :posts do
            drop_column :id
          end
        end
      end
    CONTENT
  end

  include_context "task"
  include_context "migration"
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$data_app_boilerplate)

      source :posts do
        attribute :title
      end
    end
  end

  it "creates a migration for each finalized change" do
    expect(migrations.count).to eq(1)
    Rake::Task["db:finalize"].reenable
    Rake::Task["db:finalize"].invoke("sql", "default")
    expect(migrations.count).to eq(2)
    expect(migrations[1]).to include("change_posts")
    expect(File.read(migrations[1])).to eq(finalized_migration_content)
  end
end
