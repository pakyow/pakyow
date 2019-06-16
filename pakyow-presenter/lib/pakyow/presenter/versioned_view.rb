# frozen_string_literal: true

require "delegate"

module Pakyow
  module Presenter
    # Wraps one or more versioned view objects. Provides an interface for manipulating multiple
    # view versions as if they were a single object, picking one to use for presentation.
    #
    class VersionedView < SimpleDelegator
      DEFAULT_VERSION = :default

      attr_reader :names

      def initialize(versions)
        @versions = versions
        @names = self.versions.map { |versioned_view| versioned_view.label(:version) }
        determine_working_version
        @used = false
      end

      def initialize_dup(_)
        super

        @versions = @versions.map(&:dup)
        @names = @names.map(&:dup)
        determine_working_version
      end

      def soft_copy
        instance = self.class.allocate

        instance.instance_variable_set(:@versions, @versions.map { |version|
          version.soft_copy
        })

        instance.instance_variable_set(:@names, @names)
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

        tap do
          if view = version_named(version)
            case view.object
            when StringDoc::MetaNode
              versioned_node = view.object.internal_nodes.find { |node|
                version == (node.label(:version) || DEFAULT_VERSION).to_sym
              }

              versioned_node.set_label(:versioned, true)
            else
              view.object.set_label(:versioned, true)
            end

            self.versioned_view = view

            cleanup
          else
            cleanup(all: true)
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
        @versions.each do |version|
          version.bind(object)
        end

        yield self, object if block_given?
      end

      def used?
        @versions.any? { |versioned_view|
          case versioned_view.object
          when StringDoc::MetaNode
            versioned_view.object.nodes.any? { |node|
              node.labeled?(:versioned)
            }
          else
            versioned_view.object.labeled?(:versioned)
          end
        }
      end

      def versions
        @versions.each_with_object([]) { |versioned_view, versions|
          case versioned_view.object
          when StringDoc::MetaNode
            versioned_view.object.nodes.each do |node|
              versions << View.from_object(node)
            end
          else
            versions << versioned_view
          end
        }
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end

      private

      def cleanup(all: false)
        if all
          while version = @versions.shift
            version.remove
          end
        else
          versions_to_remove = []

          @versions.each do |versioned_view|
            case versioned_view.object
            when StringDoc::MetaNode
              nodes_to_remove = []

              versioned_view.object.internal_nodes.each do |node|
                if !node.is_a?(StringDoc::MetaNode) && !node.labeled?(:versioned)
                  nodes_to_remove << node
                end
              end

              nodes_to_remove.each(&:remove)
            else
              unless versioned_view.object.labeled?(:versioned)
                versions_to_remove << versioned_view
              end
            end
          end

          versions_to_remove.each do |versioned_view|
            versioned_view.remove; @versions.delete(versioned_view)
          end
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
            view.object.internal_nodes.any? { |node|
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
