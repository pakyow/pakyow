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
            grouped_sources = @sources.group_by { |source|
              source.dataset_table
            }

            # Create any new sources, without foreign keys since they could reference a source that does not yet exist.
            #
            grouped_sources.each do |_table, sources|
              if migrator.create_source?(sources[0])
                combined_attributes = sources.each_with_object({}) { |source, hash|
                  hash.merge!(source.attributes)
                }.reject { |_name, attribute|
                  attribute.meta[:foreign_key]
                }

                migrator.create_source!(sources[0], combined_attributes)
              end
            end

            # Create any new associations between sources, now that we're sure everything exists.
            #
            grouped_sources.each do |_table, sources|
              combined_foreign_keys = sources.each_with_object({}) { |source, hash|
                hash.merge!(source.attributes)
              }.select { |_name, attribute|
                attribute.meta[:foreign_key]
              }

              if migrator.change_source?(sources[0], combined_foreign_keys)
                migrator.reassociate_source!(sources[0], combined_foreign_keys)
              end
            end

            # Change any existing sources, including adding / removing attributes.
            #
            grouped_sources.each do |_table, sources|
              unless migrator.create_source?(sources[0])
                combined_attributes = sources.each_with_object({}) { |source, hash|
                  hash.merge!(source.attributes)
                }.reject { |_name, attribute|
                  attribute.meta[:foreign_key]
                }

                if migrator.change_source?(sources[0], combined_attributes)
                  migrator.change_source!(sources[0], combined_attributes)
                end
              end
            end
          end
        end
      end
    end
  end
end
