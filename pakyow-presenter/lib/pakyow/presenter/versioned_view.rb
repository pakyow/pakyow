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

      def initialize(view)
        __setobj__(view)
        @names = view.object.nodes.map { |node| node.label(:version) }
        @used = false
      end

      def initialize_dup(_)
        super

        @versions = @versions.map(&:dup)
        @names = @names.map(&:dup)
      end

      # @api private
      def soft_copy
        instance = self.class.allocate
        instance.__setobj__(__getobj__.soft_copy)
        instance.instance_variable_set(:@names, @names)
        instance.instance_variable_set(:@used, @used)
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
        if node = version_named(version.to_sym)
          View.from_object(node)
        else
          nil
        end
      end

      # Uses the view matching +version+, removing all other versions.
      #
      def use(version)
        version = version.to_sym

        if node = version_named(version)
          node.set_label(:versioned, true)
          cleanup
        else
          cleanup(all: true)
        end

        self
      end

      def used?
        __getobj__.object.internal_nodes.any? { |node|
          node.labeled?(:versioned)
        }
      end

      def versions
        __getobj__.object.nodes.map { |node|
          View.from_object(node)
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
          remove
        else
          nodes_to_remove = []

          __getobj__.object.internal_nodes.each do |node|
            unless node.is_a?(StringDoc::MetaNode) || node.labeled?(:versioned)
              nodes_to_remove << node
            end
          end

          nodes_to_remove.each(&:remove)
        end
      end

      def version_named(version)
        __getobj__.object.internal_nodes.find { |node|
          version == (node.label(:version) || DEFAULT_VERSION).to_sym
        }
      end
    end
  end
end
