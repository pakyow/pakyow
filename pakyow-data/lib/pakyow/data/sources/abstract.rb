# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  module Data
    module Sources
      class Abstract < SimpleDelegator
        extend Support::ClassState
        class_state :__finalized, default: false, inheritable: true

        def initialize(dataset)
          __setobj__(dataset)
        end

        # @api private
        attr_reader :original_results

        # @api private
        def qualifications
          {}
        end

        # @api private
        def command?(_maybe_command_name)
          false
        end

        # @api private
        def query?(_maybe_query_name)
          false
        end

        # @api private
        def modifier?(_maybe_modifier_name)
          false
        end

        # @api private
        def source_from_self(dataset = __getobj__)
          self.class.source_from_source(self, dataset)
        end

        class << self
          attr_reader :container

          def instance
            container.source(plural_name)
          end

          # @api private
          attr_writer :container

          # @api private
          def plural_name
            Support.inflector.pluralize(__object_name.name).to_sym
          end

          # @api private
          def singular_name
            Support.inflector.singularize(__object_name.name).to_sym
          end

          # @api private
          def source_from_source(source, dataset)
            source.dup.tap do |duped_source|
              duped_source.__setobj__(dataset)
            end
          end

          # @api private
          def finalized!
            @__finalized = true
          end

          # @api private
          def finalized?
            @__finalized == true
          end
        end
      end
    end
  end
end
