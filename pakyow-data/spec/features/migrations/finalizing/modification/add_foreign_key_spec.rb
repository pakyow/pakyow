RSpec.describe "finalizing migration for a new foreign key" do
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

  let :comment_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :comments do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  let :initial_migration_content do
    {
      "20180503000000_create_posts.rb" => post_migration_content,
      "20180503000001_create_comments.rb" => comment_migration_content
    }
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          alter_table :comments do
            add_foreign_key :post_id, :posts
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

        has_many :comments
      end

      source :comments do
        primary_id
        attribute :title
      end
    end
  end

  it "creates a migration for each finalized change" do
    expect(migrations.count).to eq(2)
    Rake::Task["db:finalize"].reenable
    Rake::Task["db:finalize"].invoke("sql", "default")
    expect(migrations.count).to eq(3)
    expect(migrations[2]).to include("change_comments")
    expect(File.read(migrations[2])).to eq(finalized_migration_content)
  end
end
