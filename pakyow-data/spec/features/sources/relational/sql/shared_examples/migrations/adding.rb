RSpec.shared_examples :source_migrations_adding do |types:|
  describe "adding a new attribute to an existing relational source" do
    let :app_def do
      context = self

      Proc.new do
        source :posts, timestamps: false do
          # Define an attribute for every type.
          #
          types.keys.each do |type|
            attribute :"test_#{type}", type
          end
        end
      end
    end

    let :initial_migration_content do
      {
        "20180503000000_create_posts.rb" => <<~CONTENT
          Pakyow.migration do
            change do
              create_table :posts do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT
      }
    end

    shared_examples :migrated do
      it "adds a column for each attribute" do
        types.each_with_index do |(name, type), i|
          column = schema(:posts).find { |column_name, options|
            column_name == :"test_#{name}"
          }

          expect(column).to_not be(nil)
          expect(column[1][:type]).to eq(
            data_connection.adapter.finalized_attribute(type).meta[:column_type]
          )
        end
      end
    end

    describe "finalizing" do
      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                add_column :test_boolean, :boolean
                add_column :test_date, :date
                add_column :test_datetime, :datetime
                add_column :test_decimal, :decimal, size: [10, 2]
                add_column :test_float, :float
                add_column :test_integer, :integer
                add_column :test_string, :string
                add_column :test_time, :time
                add_column :test_file, :file
                add_column :test_text, :text
                add_column :test_bignum, :bignum
        CONTENT

        additional_finalized_columns.split("\n").each do |line|
          content << "      #{line}\n"
        end

        content << <<~CONTENT
              end
            end
          end
        CONTENT

        [content]
      end

      before do
        finalize_migrations(1, 2)
      end

      it "creates a migration for each finalized change" do
        expect(migrations[1]).to include("change_posts")
        expect(File.read(migrations[1])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
          setup_and_run
        end

        it "does not detect any more changes" do
          finalize_migrations(2, 2)
        end

        include_examples :migrated
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      include_examples :migrated
    end
  end

  describe "adding a new attribute with custom options to an existing relational source" do
    let :app_def do
      context = self

      Proc.new do
        source :posts, timestamps: false do
          attribute :test_custom_decimal, :decimal, size: [10, 5]
        end
      end
    end

    let :initial_migration_content do
      {
        "20180503000000_create_posts.rb" => <<~CONTENT
          Pakyow.migration do
            change do
              create_table :posts do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT
      }
    end

    shared_examples :migrated do
      it "adds the custom attribute" do
        column = schema(:posts).find { |column_name, options|
          column_name == :test_custom_decimal
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          data_connection.adapter.finalized_attribute(types[:decimal]).meta[:column_type]
        )
        expect(column[1][:db_type]).to eq(
          data_connection.adapter.finalized_attribute(data.posts.source.class.attributes[:test_custom_decimal]).meta[:native_type]
        )
      end
    end

    describe "finalizing" do
      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                add_column :test_custom_decimal, :decimal, size: [10, 5]
              end
            end
          end
        CONTENT

        [content]
      end

      before do
        finalize_migrations(1, 2)
      end

      it "creates a migration for each finalized change" do
        expect(migrations[1]).to include("change_posts")
        expect(File.read(migrations[1])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
          setup_and_run
        end

        it "does not detect any more changes" do
          finalize_migrations(2, 2)
        end

        include_examples :migrated
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      include_examples :migrated
    end
  end

  describe "adding a primary key to an existing relational source" do
    let :app_def do
      context = self

      Proc.new do
        source :posts, timestamps: false do
          attribute :foo
        end
      end
    end

    let :initial_migration_content do
      {
        "20180503000000_create_posts.rb" => <<~CONTENT
          Pakyow.migration do
            change do
              create_table :posts do
                column :foo, :string
              end
            end
          end
        CONTENT
      }
    end

    shared_examples :migrated do
      it "adds the primary key" do
        column = schema(:posts).find { |column_name, options|
          column_name == :id
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          data_connection.adapter.finalized_attribute(types[:bignum]).meta[:column_type]
        )
      end
    end

    describe "finalizing" do
      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                add_primary_key :id, type: :bignum
              end
            end
          end
        CONTENT

        [content]
      end

      before do
        finalize_migrations(1, 2)
      end

      it "creates a migration for each finalized change" do
        expect(migrations[1]).to include("change_posts")
        expect(File.read(migrations[1])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
          setup_and_run
        end

        it "does not detect any more changes" do
          finalize_migrations(2, 2)
        end

        include_examples :migrated
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      include_examples :migrated
    end
  end

  describe "adding a foreign key to an existing relational source" do
    let :app_def do
      context = self

      Proc.new do
        source :posts, timestamps: false do
        end

        source :users, timestamps: false do
          has_many :posts
        end
      end
    end

    let :initial_migration_content do
      {
        "20180503000000_create_posts.rb" => <<~CONTENT,
          Pakyow.migration do
            change do
              create_table :posts do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT

        "20180503000000_create_users.rb" => <<~CONTENT
          Pakyow.migration do
            change do
              create_table :users do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT
      }
    end

    shared_examples :migrated do
      it "adds the foreign key" do
        column = schema(:posts).find { |column_name, options|
          column_name == :user_id
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          data_connection.adapter.finalized_attribute(types[:bignum]).meta[:column_type]
        )
      end
    end

    describe "finalizing" do
      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                add_foreign_key :user_id, :users, type: :bignum
              end
            end
          end
        CONTENT

        [content]
      end

      before do
        finalize_migrations(2, 3)
      end

      it "creates a migration for each finalized change" do
        expect(migrations[2]).to include("associate_posts_with_users")
        expect(File.read(migrations[2])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
          setup_and_run
        end

        it "does not detect any more changes" do
          finalize_migrations(3, 3)
        end

        include_examples :migrated
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      include_examples :migrated
    end
  end
end
