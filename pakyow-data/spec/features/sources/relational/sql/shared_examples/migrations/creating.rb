RSpec.shared_examples :source_migrations_creating do |types:|
  describe "creating a new relational source" do
    let :app_definition do
      context = self

      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          # Define an attribute for every type.
          #
          types.keys.each do |type|
            attribute :"test_#{type}", type
          end
        end
      end
    end

    shared_examples :migrated do
      it "creates the table" do
        expect(raw_connection.table_exists?(:posts)).to be(true)
        expect(schema(:posts).count).to eq(3 + types.count)
      end

      it "creates the primary key" do
        column = schema(:posts).find { |column_name, options|
          column_name == :id
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          connection.adapter.finalized_attribute(types[:bignum]).meta[:column_type]
        )
      end

      it "creates the timestamps" do
        column = schema(:posts).find { |column_name, options|
          column_name == :created_at
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          connection.adapter.finalized_attribute(types[:datetime]).meta[:column_type]
        )

        column = schema(:posts).find { |column_name, options|
          column_name == :updated_at
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          connection.adapter.finalized_attribute(types[:datetime]).meta[:column_type]
        )
      end

      it "creates a column for each attribute" do
        types.each_with_index do |(name, type), i|
          column = schema(:posts).find { |column_name, options|
            column_name == :"test_#{name}"
          }

          expect(column).to_not be(nil)
          expect(column[1][:type]).to eq(
            connection.adapter.finalized_attribute(type).meta[:column_type]
          )
        end
      end
    end

    let :initial_migration_content do
      {}
    end

    describe "finalizing" do
      before do
        finalize_migrations(0, 1)
      end

      let :finalized_migration_content do
        content = <<~CONTENT
          Pakyow.migration do
            change do
              create_table :posts do
                primary_key :id, type: :bignum
                column :created_at, :datetime
                column :updated_at, :datetime
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

        additional_finalized_columns.split("\n").each do |line|
          content << "      #{line}\n"
        end

        content << <<~CONTENT
              end
            end
          end
        CONTENT

        content
      end

      it "creates a migration for each finalized change" do
        expect(migrations[0]).to include("create_posts")
        expect(File.read(migrations[0])).to eq(finalized_migration_content)
      end

      context "after applying the migrations" do
        before do
          run_migrations
        end

        it "does not detect any more changes" do
          finalize_migrations(1, 1)
        end

        include_examples :migrated
      end
    end

    describe "auto migrating" do
      before do
        run_migrations
        Pakyow.config.data.auto_migrate = true
        run_app
      end

      include_examples :migrated
    end
  end

  describe "creating new dependent relational sources" do
    let :app_definition do
      context = self

      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :children, timestamps: false do
        end

        source :parents, timestamps: false do
          has_many :children
        end
      end
    end

    shared_examples :migrated do
      it "creates the tables" do
        expect(raw_connection.table_exists?(:children)).to be(true)
        expect(schema(:children).count).to eq(2)

        expect(raw_connection.table_exists?(:parents)).to be(true)
        expect(schema(:parents).count).to eq(1)
      end

      it "creates the foreign key" do
        column = schema(:children).find { |column_name, options|
          column_name == :parent_id
        }

        expect(column).to_not be(nil)
        expect(column[1][:type]).to eq(
          connection.adapter.finalized_attribute(types[:bignum]).meta[:column_type]
        )
      end
    end

    let :initial_migration_content do
      {}
    end

    describe "finalizing" do
      before do
        finalize_migrations(0, 3)
      end

      let :finalized_migration_content do
        children = <<~CONTENT
          Pakyow.migration do
            change do
              create_table :children do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT

        parents = <<~CONTENT
          Pakyow.migration do
            change do
              create_table :parents do
                primary_key :id, type: :bignum
              end
            end
          end
        CONTENT

        association = <<~CONTENT
          Pakyow.migration do
            change do
              alter_table :children do
                add_foreign_key :parent_id, :parents, type: :bignum
              end
            end
          end
        CONTENT

        [children, parents, association]
      end

      it "creates a migration for each finalized change" do
        expect(migrations[0]).to include("create_children")
        expect(migrations[1]).to include("create_parents")
        expect(migrations[2]).to include("associate_children_with_parents")

        expect(File.read(migrations[0])).to eq(finalized_migration_content[0])
        expect(File.read(migrations[1])).to eq(finalized_migration_content[1])
        expect(File.read(migrations[2])).to eq(finalized_migration_content[2])
      end

      context "after applying the migrations" do
        before do
          run_migrations
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
        run_app
      end

      include_examples :migrated
    end
  end
end
