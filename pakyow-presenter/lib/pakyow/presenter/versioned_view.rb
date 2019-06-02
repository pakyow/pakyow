# frozen_string_literal: true

require "delegate"

module Pakyow
  module Presenter
    # Wraps one or more versioned view objects. Provides an interface for manipulating multiple
    # view versions as if they were a single object, picking one to use for presentation.
    #
    class VersionedView < SimpleDelegator
      DEFAULT_VERSION = :default

      # @api private
      attr_reader :versions

      def initialize(versions)
        @versions = versions
        determine_working_version
        @used = false
      end

      def initialize_dup(_)
        super

        @versions = @versions.map(&:dup)
        determine_working_version
      end

      def soft_copy
        instance = self.class.allocate

        instance.instance_variable_set(:@versions, @versions.map { |version|
          version.soft_copy
        })

        instance.instance_variable_set(:@used, @used)
        instance.send(:determine_working_version)

        instance
      end

      # Returns true if +version+ exists.
      #
      def version?(version)
        !!version_named(version.to_sym)
      end

      # Returns the view matching +version+.
      #
      def versioned(version)
        if versioned = version_named(version.to_sym)
          case versioned.object
          when StringDoc::MetaNode
            node = versioned.object.nodes.find { |n|
              version == (n.label(:version) || DEFAULT_VERSION).to_sym
            }

            View.from_object(node)
          else
            versioned
          end
        else
          nil
        end
      end

      # Uses the view matching +version+, removing all other versions.
      #
      def use(version)
        version = version.to_sym
        @used = true

        tap do
          if view = version_named(version)
            case view.object
            when StringDoc::MetaNode
              versioned_node = view.object.nodes.find { |node|
                version == (node.label(:version) || DEFAULT_VERSION).to_sym
              }

              versioned_node.delete_label(:version)
              versioned_node.set_label(:used, true)
            else
              view.object.delete_label(:version)
              view.object.set_label(:used, true)
            end

            self.versioned_view = view

            cleanup
          else
            cleanup(:all)
          end
        end
      end

      def transform(object)
        @versions.each do |version|
          version.transform(object)
        end

        yield self, object if block_given?
      end

      def bind(object)
        cleanup

        @versions.each do |version|
          version.bind(object)
        end

        yield self, object if block_given?
      end

      def used?
        @used == true
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end

      private

      def cleanup(mode = nil)
        if mode == :all
          @versions.each(&:remove)
          @versions = []
        else
          @versions.dup.each do |view_to_remove|
            case view_to_remove.object
            when StringDoc::MetaNode
              if @used
                view_to_remove.object.nodes.each do |node|
                  node.remove unless node.labeled?(:used)
                end
              else
                if default = view_to_remove.object.nodes.find { |node| node.label(:version) == DEFAULT_VERSION }
                  view_to_remove.object.nodes.each do |node|
                    node.remove unless node.equal?(default)
                  end
                else
                  view_to_remove.object.nodes[1..-1].each(&:remove)
                end
              end
            else
              unless view_to_remove == __getobj__
                view_to_remove.remove
                @versions.delete(view_to_remove)
              end
            end
          end

          __getobj__.object.delete_label(:version)
        end
      end

      def determine_working_version
        self.versioned_view = default_version
      end

      def versioned_view=(view)
        __setobj__(view)
      end

      def default_version
        version_named(DEFAULT_VERSION) || first_version
      end

      def version_named(version)
        @versions.find { |view|
          case view.object
          when StringDoc::MetaNode
            view.object.nodes.any? { |node|
              version == (node.label(:version) || DEFAULT_VERSION).to_sym
            }
          else
            view.version == version
          end
        }
      end

      def first_version
        @versions[0]
      end
    end
  end
end
