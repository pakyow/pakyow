# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Presenter
    # Wraps one or more versioned view objects. Provides an interface for manipulating multiple
    # view versions as if they were a single object, picking one to use for presentation.
    #
    class VersionedView < View
      DEFAULT_VERSION = :default

      # View that will be presented.
      #
      attr_reader :working

      def initialize(versions)
        @versions = versions
        determine_working_version
        @used = false
      end

      def initialize_copy(_)
        super

        @versions = @versions.map(&:dup)
        determine_working_version
      end

      # Returns true if +version+ exists.
      #
      def version?(version)
        !!version_named(version.to_sym)
      end

      # Returns the view matching +version+.
      #
      def versioned(version)
        version_named(version.to_sym)
      end

      # Uses the view matching +version+, removing all other versions.
      #
      def use(version)
        version = version.to_sym
        @used = true

        tap do
          if view = version_named(version)
            view.object.delete_label(:version)
            view.object.set_label(:used, true)
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

      def versioned?
        @versions.length > 1
      end

      def version?(version)
        !!version_named(version)
      end

      def used?
        @used == true
      end

      protected

      def cleanup(mode = nil)
        if mode == :all
          @versions.each(&:remove)
          @versions = []
        else
          @working.object.delete_label(:version)
          @versions.dup.each do |view_to_remove|
            unless view_to_remove == @working
              view_to_remove.remove
              @versions.delete(view_to_remove)
            end
          end
        end
      end

      def determine_working_version
        self.versioned_view = default_version
      end

      def versioned_view=(view)
        @working = view
        @object = view.object
        @version = view.version
        @attributes = view.attributes
        @info = view.info
      end

      def default_version
        version_named(DEFAULT_VERSION) || first_version
      end

      def version_named(version)
        @versions.find { |view|
          view.version == version
        }
      end

      def first_version
        @versions[0]
      end
    end
  end
end
