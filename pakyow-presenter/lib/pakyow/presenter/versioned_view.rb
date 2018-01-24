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

        tap do
          if view = version_named(version)
            view.object.delete_label(:version)
            self.versioned_view = view
          end

          # remove everything but the used version
          @versions.reject { |versioned_view| versioned_view == view }.each(&:remove)
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

      protected

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
