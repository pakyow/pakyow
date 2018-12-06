RSpec.shared_examples :source_migrations_changing do |adapter:, types:|
  describe "changing the type of an attribute for an existing relational source" do
    EXCEPTIONS = {
      mysql2: [
        "datetime:time",
        "time:datetime"
      ],
      postgres: [
        "datetime:time",
        "string:text",
        "text:string",
        "time:datetime"
      ],
      sqlite: [
        "datetime:time",
        "time:datetime"
      ]
    }

    REQUIRES_EXPLICIT_CAST = {
      postgres: [
        "bignum:boolean",
        "bignum:date",
        "bignum:datetime",
        "bignum:file",
        "bignum:json",
        "bignum:time",
        "boolean:bignum",
        "boolean:date",
        "boolean:datetime",
        "boolean:decimal",
        "boolean:file",
        "boolean:float",
        "boolean:integer",
        "boolean:json",
        "boolean:time",
        "date:bignum",
        "date:boolean",
        "date:decimal",
        "date:file",
        "date:float",
        "date:integer",
        "date:json",
        "datetime:bignum",
        "datetime:boolean",
        "datetime:decimal",
        "datetime:file",
        "datetime:float",
        "datetime:integer",
        "datetime:json",
        "decimal:boolean",
        "decimal:date",
        "decimal:datetime",
        "decimal:file",
        "decimal:json",
        "decimal:time",
        "file:bignum",
        "file:boolean",
        "file:date",
        "file:datetime",
        "file:decimal",
        "file:float",
        "file:integer",
        "file:json",
        "file:time",
        "float:boolean",
        "float:date",
        "float:datetime",
        "float:file",
        "float:json",
        "float:time",
        "integer:boolean",
        "integer:date",
        "integer:datetime",
        "integer:file",
        "integer:json",
        "integer:time",
        "json:bignum",
        "json:boolean",
        "json:date",
        "json:datetime",
        "json:decimal",
        "json:file",
        "json:float",
        "json:integer",
        "json:time",
        "string:bignum",
        "string:boolean",
        "string:date",
        "string:datetime",
        "string:decimal",
        "string:file",
        "string:float",
        "string:integer",
        "string:json",
        "string:time",
        "text:bignum",
        "text:boolean",
        "text:date",
        "text:datetime",
        "text:decimal",
        "text:file",
        "text:float",
        "text:integer",
        "text:json",
        "text:time",
        "time:bignum",
        "time:boolean",
        "time:decimal",
        "time:file",
        "time:float",
        "time:integer",
        "time:json"
      ]
    }

    types.reject { |type|
      # We don't care about primary key types here.
      #
      type.to_s.start_with?("pk_")
    }.each do |from_type_name, from_type|
      types.reject { |type|
        # We don't care about primary key types here.
        #
        type.to_s.start_with?("pk_")
      }.each do |to_type_name, to_type|
        context "changing from #{from_type_name} to #{to_type_name}" do
          let :app_definition do
            context = self

            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                attribute :"test_#{from_type_name}_to_#{to_type_name}", to_type
              end
            end
          end

          shared_examples :migrated do
            it "changes the column" do
              column = schema(:posts).find { |name, options|
                name == :"test_#{from_type_name}_to_#{to_type_name}"
              }

              expect(column).to_not be(nil)
              expect(column[1][:type]).to eq(
                connection.adapter.finalized_attribute(to_type).meta[:column_type]
              )
            end
          end

          let :initial_migration_content do
            {
              "20180503000000_create_posts.rb" => <<~CONTENT
                Pakyow.migration do
                  change do
                    create_table :posts do
                      column :test_#{from_type_name}_to_#{to_type_name}, #{from_type_name.inspect}#{migrator.send(:column_opts_string_for_attribute, from_type)}
                    end
                  end
                end
              CONTENT
            }
          end

          describe "finalizing" do
            let :finalized_migration_content do
              <<~CONTENT
                Pakyow.migration do
                  change do
                    alter_table :posts do
                      set_column_type :test_#{from_type_name}_to_#{to_type_name}, #{to_type_name.inspect}#{migrator.send(:column_opts_string_for_attribute, to_type)}
                    end
                  end
                end
              CONTENT
            end

            if from_type_name == to_type_name || EXCEPTIONS[adapter].to_a.include?("#{from_type_name}:#{to_type_name}")
              it "does not change" do
                finalize_migrations(1, 1)
              end
            else
              before do
                finalize_migrations(1, 2)
              end

              it "creates a migration for each finalized change" do
                expect(migrations[1]).to include("change_posts")
                expect(File.read(migrations[1])).to eq(finalized_migration_content)
              end

              if REQUIRES_EXPLICIT_CAST[adapter].to_a.include?("#{from_type_name}:#{to_type_name}")
                # Changes that require an explicit cast will still be exported to a migration, but
                # it's up to the developer to pick which cast to use. It's likely we can make this
                # a nicer developer experience, but it's an edge case that we haven't gotten to.
                #
                it "requires an explicit cast that will be handled in the future"
              else
                context "after applying the change" do
                  before do
                    run_migrations
                  end

                  it "does not detect the change again" do
                    finalize_migrations(2, 2)
                  end

                  include_examples :migrated
                end
              end
            end
          end

          describe "auto migrating" do
            if REQUIRES_EXPLICIT_CAST[adapter].to_a.include?("#{from_type_name}:#{to_type_name}")
              # Changes that require an explicit cast will still be exported to a migration, but
              # it's up to the developer to pick which cast to use. It's likely we can make this
              # a nicer developer experience, but it's an edge case that we haven't gotten to.
              #
              it "requires an explicit cast that will be handled in the future"
            else
              before do
                run_migrations
                Pakyow.config.data.auto_migrate = true
                run_app
              end

              include_examples :migrated
            end
          end
        end
      end
    end
  end
end
