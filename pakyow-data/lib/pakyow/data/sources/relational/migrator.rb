# frozen_string_literal: true

module Pakyow
  module Data
    module Sources
      class Relational
        class Migrator
          def initialize(connection, sources: [])
            @connection, @sources = connection, sources
          end

          def auto_migrate!
            if @sources.any?
              migrate!(automator)
            end
          end

          def finalize!
            if @sources.any?
              migrator = finalizer
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

          private

          def automator
            self
          end

          def finalizer
            self
          end

          def migrate!(migrator)
            # Create any new sources, without foreign keys since they could reference a source that does not yet exist.
            #
            @sources.each do |source|
              if migrator.create_source?(source)
                migrator.create_source!(source, source.attributes.reject { |_name, attribute| attribute.meta[:foreign_key] })
              end
            end

            # Create any new associations between sources, now that we're sure everything exists.
            #
            @sources.each do |source|
              foreign_keys = source.attributes.select { |_name, attribute|
                attribute.meta[:foreign_key]
              }

              if migrator.change_source?(source, foreign_keys)
                migrator.reassociate_source!(source, foreign_keys)
              end
            end

            # Change any existing sources, including adding / removing attributes.
            #
            @sources.each do |source|
              unless migrator.create_source?(source)
                attributes = source.attributes.reject { |_name, attribute|
                  attribute.meta[:foreign_key]
                }

                if migrator.change_source?(source, attributes)
                  migrator.change_source!(source, attributes)
                end
              end
            end
          end
        end
      end
    end
  end
end
