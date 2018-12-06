# frozen_string_literal: true

module Pakyow
  module Data
    module Sources
      class Relational
        class Migrator
          def initialize(sources, connection)
            @sources, @connection = sources, connection
          end

          def auto_migrate!
            if @sources.any?
              require "pakyow/data/adapters/#{@sources.first.adapter}/migrators/automatic"
              migrate!(@connection.adapter.class.const_get(:Migrators).const_get(:Automatic).new(@connection))
            end
          end

          def finalize!
            if @sources.any?
              require "pakyow/data/adapters/#{@sources.first.adapter}/migrators/finalizer"
              migrator = @connection.adapter.class.const_get(:Migrators).const_get(:Finalizer).new(@connection)
              migrate!(migrator)

              # Return the migrations that need to be created.
              #
              prefix = Time.now.strftime("%Y%m%d%H%M%S").to_i
              migrator.migrations.each_with_object({}) { |(action, content), migrations|
                migrations["#{prefix}_#{action}.rb"] = content

                # Ensure that migration files appear in the correct order.
                #
                prefix += 1
              }
            else
              {}
            end
          end

          def run!(migration_path)
            require "pakyow/data/adapters/#{@sources.first.adapter}/runner"
            @connection.adapter.class.const_get(:Runner).new(@connection, migration_path).perform
          end

          private

          def migrate!(migrator)
            # Create any new sources, without foreign keys since they could reference a source that does not yet exist.
            #
            @sources.each do |source|
              if migrator.create?(source)
                migrator.create!(source, source.attributes.reject { |_name, attribute| attribute.meta[:foreign_key] })
              end
            end

            # Create any new associations between sources, now that we're sure everything exists.
            #
            @sources.each do |source|
              foreign_keys = source.attributes.select { |_name, attribute|
                attribute.meta[:foreign_key]
              }

              if migrator.change?(source, foreign_keys)
                migrator.reassociate!(source, foreign_keys)
              end
            end

            # Change any existing sources, including adding / removing attributes.
            #
            @sources.each do |source|
              unless migrator.create?(source)
                attributes = source.attributes.reject { |_name, attribute|
                  attribute.meta[:foreign_key]
                }

                if migrator.change?(source, attributes)
                  migrator.change!(source, attributes)
                end
              end
            end
          end
        end
      end
    end
  end
end
