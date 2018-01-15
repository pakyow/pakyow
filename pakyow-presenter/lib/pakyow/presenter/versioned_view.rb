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

      # Returns the view matching +version+.
      #
      def versioned(version)
        version_named(version)
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

      # Transforms the versioned view to match +data+.
      #
      def transform(data)
        if ((data.respond_to?(:empty?) && data.empty?) || data.nil?) && version_named(:empty)
          use(:empty)
        else
          if !data.respond_to?(:each) || data.is_a?(Hash)
            data = Array.ensure(data)
          end

          template = dup
          insertable = self
          versioned_view = self

          data.each do |object|
            if block_given?
              yield versioned_view, object
            end

            versioned_view.working.transform(object)

            unless versioned_view == self
              insertable.after(versioned_view)
              insertable = versioned_view
            end

            versioned_view = template.dup
          end
        end

        self
      end

      protected

      def determine_working_version
        self.versioned_view = default_version || first_version
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
        @versions.each do |view|
          return view if view.version == version
        end

        nil
      end

      def first_version
        @versions[0]
      end
    end
  end
end
