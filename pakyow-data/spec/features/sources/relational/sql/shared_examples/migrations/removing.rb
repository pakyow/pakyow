RSpec.shared_examples :source_migrations_removing do |types:|
  describe "removing an attribute from an existing relational source" do
    let :app_init do
      context = self

      Proc.new do
        source :posts, timestamps: false do
        end
      end
    end

    let :initial_migration_content do
      content = <<~CONTENT
        Pakyow.migration do
          change do
            create_table :posts do
              primary_key :id, type: :bignum
              column :test_boolean, :boolean
              column :test_date, :date
              column :test_datetime, :datetime
              column :test_decimal, :decimal, size: [10, 2]
              column :test_float, :float
              column :test_integer, :integer
              column :test_string, :string
              column :test_time, :time
              column :test_file, :file
              column :test_text, :text
              column :test_bignum, :bignum
      CONTENT

      additional_initial_columns.split("\n").each do |line|
        content << "      #{line}\n"
      end

      content << <<~CONTENT
            end
          end
        end
      CONTENT

      {
        "20180503000001_create_posts.rb" => content
      }
    end

    describe "finalizing" do
      before do
        finalize_migrations(1, 2)
      end

      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                drop_column :test_boolean
                drop_column :test_date
                drop_column :test_datetime
                drop_column :test_decimal
                drop_column :test_float
                drop_column :test_integer
                drop_column :test_string
                drop_column :test_time
                drop_column :test_file
                drop_column :test_text
                drop_column :test_bignum
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

      it "creates a migration for each finalized change" do
        expect(migrations[1]).to include("change_posts")
        expect(File.read(migrations[1])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
        end

        it "does not detect any more changes" do
          finalize_migrations(2, 2)
        end

        it "removes the column for each attribute" do
          types.each_with_index do |(name, type), i|
            column = schema(:posts).find { |column_name, options|
              column_name == :"test_#{name}"
            }

            expect(column).to be(nil)
          end
        end
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      it "does not remove the column for each attribute" do
        types.each_with_index do |(name, type), i|
          column = schema(:posts).find { |column_name, options|
            column_name == :"test_#{name}"
          }

          expect(column).to_not be(nil)
        end
      end
    end
  end

  describe "removing a primary key from an existing relational source" do
    let :app_init do
      context = self

      Proc.new do
        source :posts, primary_id: false, timestamps: false do
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
                primary_key :id, type: :bignum
                column :foo, :string
              end
            end
          end
        CONTENT
      }
    end

    describe "finalizing" do
      before do
        finalize_migrations(1, 2)
      end

      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                drop_column :id
              end
            end
          end
        CONTENT

        [content]
      end

      it "creates a migration for each finalized change" do
        expect(migrations[1]).to include("change_posts")
        expect(File.read(migrations[1])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
        end

        it "does not detect any more changes" do
          finalize_migrations(2, 2)
        end

        it "removes the primary key" do
          column = schema(:posts).find { |column_name, options|
            column_name == :id
          }

          expect(column).to be(nil)
        end
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      it "does not remove the primary key" do
        column = schema(:posts).find { |column_name, options|
          column_name == :id
        }

        expect(column).to_not be(nil)
      end
    end
  end

  describe "removing a foreign key from an existing relational source" do
    let :app_init do
      context = self

      Proc.new do
        source :posts, timestamps: false do
        end

        source :users, timestamps: false do
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

        "20180503000001_create_users.rb" => <<~CONTENT,
          Pakyow.migration do
            change do
              create_table :users do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT

        "20180503000002_associate_posts_with_users_.rb" => <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                add_foreign_key :user_id, :users, type: :bignum
              end
            end
          end
        CONTENT
      }
    end

    describe "finalizing" do
      before do
        finalize_migrations(3, 4)
      end

      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :posts do
                drop_column :user_id
              end
            end
          end
        CONTENT

        [content]
      end

      it "creates a migration for each finalized change" do
        expect(migrations[3]).to include("change_posts")
        expect(File.read(migrations[3])).to eq(finalized_migration_content[0])
      end

      context "after applying the migrations" do
        before do
          run_migrations
        end

        it "does not detect any more changes" do
          finalize_migrations(4, 4)
        end

        it "removes the foreign key" do
          column = schema(:posts).find { |column_name, options|
            column_name == :user_id
          }

          expect(column).to be(nil)
        end
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        setup_and_run
      end

      it "does not remove the foreign key" do
        column = schema(:posts).find { |column_name, options|
          column_name == :user_id
        }

        expect(column).to_not be(nil)
      end
    end
  end

  describe "removing an existing relational source" do
    it "will be supported in the future"
  end

  describe "removing two existing dependent relational sources" do
    it "will be supported in the future"
  end
end
