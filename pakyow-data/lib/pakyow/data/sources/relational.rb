# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/makeable"
require "pakyow/support/class_state"
require "pakyow/support/inflector"

require "pakyow/data/sources/base"

module Pakyow
  module Data
    module Sources
      # A relational data source through which you interact with a persistence
      # layer such as a sql database, redis, or http. Defines the schema, queries,
      # and other adapter-specific metadata (e.g. sql table).
      #
      # Each adapter provides its own interface for interacting with the underlying
      # persistence layer. For example, the sql adapter exposes +Sequel::Dataset+
      # provided by the *fantastic* Sequel gem.
      #
      # In normal use, the underlying dataset is inaccessible from outside of the
      # source. Instead, access to the dataset occurs through queries defined on
      # the source that interact with the dataset and return a result.
      #
      # Results are always returned as a new source instance (or when used from
      # the app, a {Pakyow::Data::Proxy} object). Access to the underlying value
      # is provided through methods such as +one+, +to_a+, and +each+.
      # (@see Pakyow::Data::Container#wrap_defined_queries!)
      #
      # Mutations occur through commands. Commands do not implement validation
      # other than checking for required attributes and checking that the given
      # attributes are defined on the source. Use the input verifier pattern to
      # verify and validate input before passing it to a command
      # (@see Pakyow::Verifier).
      #
      # @example
      #   source :posts, adapter: :sql, connection: :default do
      #     table :posts
      #
      #     primary_id
      #     timestamps
      #
      #     attribute :title, :string
      #
      #     command :create do |params|
      #       insert(params)
      #     end
      #
      #     def by_id(id)
      #       where(id: id)
      #     end
      #   end
      #
      #   data.posts.create(title: "foo")
      #   data.posts.by_id(1).first
      #   => #<Pakyow::Data::Object @values={:id => 1, :title => "foo", :created_at => "2018-11-30 10:55:05 -0800", :updated_at => "2018-11-30 10:55:05 -0800"}>
      #
      class Relational < Sources::Base
        require "pakyow/data/sources/relational/associations/belongs_to"
        require "pakyow/data/sources/relational/associations/has_many"
        require "pakyow/data/sources/relational/associations/has_one"
        require "pakyow/data/sources/relational/associations/through"

        require "pakyow/data/sources/relational/command"
        require "pakyow/data/sources/relational/migrator"

        # @api private
        attr_reader :included

        def initialize(*)
          super

          @wrap_as = self.class.singular_name
          @included = []

          if default_query = self.class.__default_query
            result = if default_query.is_a?(Proc)
              instance_exec(&default_query)
            else
              public_send(self.class.__default_query)
            end

            result = case result
            when self.class
              result.__getobj__
            else
              result
            end

            __setobj__(result)
          end
        end

        def including(association_name, &block)
          tap do
            association_name = association_name.to_sym

            association_to_include = self.class.associations.values.flatten.find { |association|
              association.name == association_name
            } || raise(UnknownAssociation.new("unknown association `#{association_name}'").tap { |error| error.context = self.class })

            included_source = association_to_include.associated_source.instance

            if association_to_include.query
              included_source = included_source.send(association_to_include.query)
            end

            final_source = if block_given?
              included_source.instance_exec(&block) || included_source
            else
              included_source
            end

            @included << [association_to_include, final_source]
          end
        end

        def as(object)
          tap do
            @wrap_as = object
          end
        end

        def limit(count)
          __setobj__(__getobj__.limit(count)); self
        end

        def order(*ordering)
          __setobj__(
            __getobj__.order(
              *ordering.flat_map { |order|
                case order
                when Array
                  Sequel.public_send(order[1].to_sym, order[0].to_sym)
                when Hash
                  order.each_pair.map { |key, value|
                    Sequel.public_send(value.to_sym, key.to_sym)
                  }
                else
                  Sequel.asc(order.to_s.to_sym)
                end
              }
            )
          ); self
        end

        def to_a
          return @results if instance_variable_defined?(:@results)
          @results = self.class.to_a(__getobj__)
          include_results!(@results)
          @results.map! { |result|
            finalize(result)
          }
        end
        alias all to_a

        def one
          return @results.first if instance_variable_defined?(:@results)
          return @result if instance_variable_defined?(:@result)

          if result = self.class.one(__getobj__)
            include_results!([result])
            @result = finalize(result)
          else
            nil
          end
        end

        def transaction(&block)
          self.class.container.connection.transaction(&block)
        end

        def transaction?
          self.class.container.connection.adapter.connection.in_transaction?
        end

        def on_commit(&block)
          self.class.container.connection.adapter.connection.after_commit(&block)
        end

        def on_rollback(&block)
          self.class.container.connection.adapter.connection.after_rollback(&block)
        end

        def command(command_name)
          if command = self.class.commands[command_name]
            Command.new(
              command_name,
              block: command[:block],
              source: self,
              provides_dataset: command[:provides_dataset],
              creates: command[:creates],
              updates: command[:updates],
              deletes: command[:deletes]
            )
          else
            raise(
              UnknownCommand.new_with_message(command: command_name).tap do |error|
                error.context = self.class
              end
            )
          end
        end

        def count
          if self.class.respond_to?(:count)
            self.class.count(__getobj__)
          else
            super
          end
        end

        # @api private
        IVARS_TO_RELOAD = %i(
          @results @result
        )

        def reload
          IVARS_TO_RELOAD.select { |ivar|
            instance_variable_defined?(ivar)
          }.each do |ivar|
            remove_instance_variable(ivar)
          end

          self
        end

        def to_json(*)
          to_a.to_json
        end

        # @api private
        def source_name
          self.class.object_name.name
        end

        # @api private
        def command?(maybe_command_name)
          self.class.commands.include?(maybe_command_name)
        end

        # @api private
        def query?(maybe_query_name)
          self.class.queries.include?(maybe_query_name)
        end

        # @api private
        MODIFIER_METHODS = %i(as including limit order).freeze
        # @api private
        def modifier?(maybe_modifier_name)
          MODIFIER_METHODS.include?(maybe_modifier_name)
        end

        # @api private
        NESTED_METHODS = %i(including).freeze
        # @api private
        def block_for_nested_source?(maybe_nested_name)
          NESTED_METHODS.include?(maybe_nested_name)
        end

        private

        def finalize(result)
          wrap(typecast(filter_to_attributes(result)))
        end

        def filter_to_attributes(result)
          result.keep_if { |key, _|
            self.class.attributes.include?(key) || self.class.association_with_name?(key) || key[0..1] == "__"
          }
        end

        def typecast(result)
          result.each do |key, value|
            unless value.nil? || !self.class.attributes.include?(key)
              result[key] = self.class.attributes[key][value]
            end
          end

          result
        end

        def wrap(result)
          wrapped_result = if @wrap_as.is_a?(Class)
            @wrap_as.new(result)
          else
            self.class.container.object(@wrap_as).new(result)
          end

          if wrapped_result.is_a?(Object)
            wrapped_result.originating_source = self.class
          end

          wrapped_result
        end

        def include_results!(results)
          @included.each do |association, combined_source|
            combined_source = combined_source.source_from_self(
              combined_source.__getobj__.dup
            )

            group_by_key, assign_by_key, remove_keys = if association.type == :through
              joining_source = association.joining_source.instance

              if combined_source.class == association.joining_source
                combined_source.__setobj__(
                  combined_source.class.container.connection.adapter.result_for_attribute_value(
                    combined_source.class.container.connection.adapter.qualify_attribute(
                      association.right_foreign_key_field, combined_source
                    ),
                    results.map { |result| result[association.associated_query_field] },
                    combined_source
                  )
                )
              else
                aliased = "__#{SecureRandom.hex(4)}".to_sym

                if joining_source.class.container.connection == combined_source.class.container.connection
                  # Optimize with joins.
                  #
                  combined_source.__setobj__(
                    combined_source.class.container.connection.adapter.restrict_to_source(
                      combined_source,
                      combined_source.class.container.connection.adapter.result_for_attribute_value(
                        combined_source.class.container.connection.adapter.qualify_attribute(
                          association.right_foreign_key_field, joining_source
                        ),
                        joining_source.class.container.connection.adapter.restrict_to_attribute(
                          association.query_field, source_from_self(__getobj__.dup)
                        ),
                        combined_source.class.container.connection.adapter.merge_results(
                          association.left_foreign_key_field,
                          association.associated_source.primary_key_field,
                          joining_source,
                          combined_source
                        )
                      ),
                      combined_source.class.container.connection.adapter.alias_attribute(
                        combined_source.class.container.connection.adapter.qualify_attribute(
                          association.right_foreign_key_field, joining_source
                        ), aliased
                      )
                    )
                  )
                else
                  # Manually join.
                  #
                  self_ids = self.class.container.connection.adapter.restrict_to_attribute(
                    self.class.primary_key_field, self
                  ).map { |result|
                    result[self.class.primary_key_field]
                  }

                  joined_results = joining_source.class.container.connection.adapter.restrict_to_attribute(
                    [association.right_foreign_key_field, association.left_foreign_key_field],
                    joining_source.class.container.connection.adapter.result_for_attribute_value(
                      association.right_foreign_key_field, self_ids, joining_source
                    )
                  )

                  combined_results = combined_source.class.container.connection.adapter.result_for_attribute_value(
                    combined_source.class.primary_key_field, joined_results.map { |result| result[association.left_foreign_key_field] }, combined_source
                  )

                  combined_results = joined_results.map { |joined_result|
                    combined_results.find { |result|
                      result[combined_source.class.primary_key_field] == joined_result[association.left_foreign_key_field]
                    }.dup.tap do |combined_result|
                      combined_result[aliased] = joined_result[association.right_foreign_key_field]
                    end
                  }
                end
              end

              [aliased, association.name, [aliased]]
            else
              combined_source.__setobj__(
                combined_source.class.container.connection.adapter.result_for_attribute_value(
                  association.associated_query_field,
                  results.map { |result| result[association.query_field] },
                  combined_source
                )
              )

              [association.associated_query_field, association.name, []]
            end

            # Group the raw results by associated column value.
            #
            combined_results = (combined_results || combined_source).to_a.group_by { |combined_result|
              combined_result[group_by_key]
            }

            # Add each result group to its associated object.
            #
            results.map! { |result|
              combined_results_for_result = combined_results[result[association.query_field]].to_a.map! { |combined_result|
                if combined_result.is_a?(Pakyow::Data::Object)
                  combined_result = combined_result.values.dup
                end

                # Remove any keys, such as temporary values used for grouping.
                #
                remove_keys.each do |remove_key|
                  combined_result.delete(remove_key)
                end

                # Wrap the result into the appropriate data object.
                #
                combined_source.send(:wrap, combined_result)
              }

              result[assign_by_key] = if association.result_type == :one
                combined_results_for_result[0]
              else
                combined_results_for_result
              end

              result
            }
          end
        end

        include Support::Hookable
        include Support::Makeable

        on "make" do
          if defined?(@adapter)
            adapter_class = Connection.adapter(@adapter)

            if adapter_class.const_defined?("SourceExtension")
              # Extend the source with any adapter-specific behavior.
              #
              extension_module = adapter_class.const_get("SourceExtension")
              unless ancestors.include?(extension_module)
                include(extension_module)
              end

              # Define default fields
              #
              self.primary_id if defined?(@primary_id) && @primary_id
              self.timestamps if defined?(@timestamps) && @timestamps
            end
          end
        end

        extend Support::ClassState
        class_state :__default_query
        class_state :timestamp_fields
        class_state :primary_key_field
        class_state :attributes, default: {}
        class_state :qualifications, default: {}, reader: false
        class_state :associations, default: { belongs_to: [], has_many: [], has_one: [] }
        class_state :commands, default: {}

        class << self
          attr_reader :adapter, :connection

          def command(command_name, provides_dataset: true, creates: false, updates: false, deletes: false, &block)
            @commands[command_name] = {
              block: block,
              provides_dataset: provides_dataset,
              creates: creates,
              updates: updates,
              deletes: deletes
            }
          end

          def queries
            instance_methods - superclass.instance_methods
          end

          def query(query_name = nil, &block)
            @__default_query = query_name || block
          end

          def timestamps(create: :created_at, update: :updated_at)
            @timestamp_fields = {
              create: create,
              update: update
            }

            attribute create, :datetime
            attribute update, :datetime
          end

          def primary_id
            primary_key :id
            attribute :id, default_primary_key_type
          end

          def primary_key(field)
            @primary_key_field = field
          end

          def primary_key_type
            case primary_key_attribute
            when Hash
              primary_key_attribute[:type]
            else
              primary_key_attribute.meta[:mapping]
            end
          end

          def primary_key_attribute
            attributes[@primary_key_field]
          end

          def default_primary_key_type
            :integer
          end

          def attribute(name, type = :string, **options)
            attributes[name.to_sym] = {
              type: type,
              options: options
            }
          end

          def subscribe(query_name, qualifications)
            @qualifications[query_name] = qualifications
          end

          def qualifications(query_name)
            @qualifications.dig(query_name) || {}
          end

          def belongs_to(association_name, query: nil, source: association_name)
            Associations::BelongsTo.new(
              name: association_name, query: query, source: self, associated_source_name: source
            ).tap do |association|
              @associations[:belongs_to] << association
            end
          end

          # rubocop:disable Naming/PredicateName
          def has_many(association_name, query: nil, source: association_name, as: singular_name, through: nil, dependent: :raise)
            Associations::HasMany.new(
              name: association_name, query: query, source: self, associated_source_name: source, as: as, dependent: dependent
            ).tap do |association|
              @associations[:has_many] << association

              if through
                setup_as_through(association, through: through)
              end
            end
          end
          # rubocop:enable Naming/PredicateName

          # rubocop:disable Naming/PredicateName
          def has_one(association_name, query: nil, source: association_name, as: singular_name, through: nil, dependent: :raise)
            Associations::HasOne.new(
              name: association_name, query: query, source: self, associated_source_name: source, as: as, dependent: dependent
            ).tap do |association|
              @associations[:has_one] << association

              if through
                setup_as_through(association, through: through)
              end
            end
          end
          # rubocop:enable Naming/PredicateName

          def setup_as_through(association, through:)
            Associations::Through.new(association, joining_source_name: through).tap do |through_association|
              associations[association.specific_type][
                associations[association.specific_type].index(association)
              ] = through_association
            end
          end

          # @api private
          def source_from_source(*)
            super.tap(&:reload)
          end

          # @api private
          def find_association_to_source(source)
            associations.values.flatten.find { |association|
              association.associated_source == source.class
            }
          end

          # @api private
          def association_with_name?(name)
            associations.values.flatten.find { |association|
              association.name == name
            }
          end
        end
      end
    end
  end
end
