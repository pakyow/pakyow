RSpec.describe "finalizing migration for a new source" do
  let :initial_migration_content do
    {
      "20180503000000_create_posts.rb" => <<~CONTENT
        Pakyow.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, String
            end
          end
        end
      CONTENT
    }
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :comments do
            primary_key :id
            column :title, String
            column :popularity, BigDecimal, size: [10, 2]
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
        primary_id
        attribute :title
      end

      source :comments do
        primary_id
        attribute :title
        attribute :popularity, :decimal
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
