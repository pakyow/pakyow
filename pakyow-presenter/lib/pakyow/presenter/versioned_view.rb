require "forwardable"

module Pakyow
  module Presenter
    class VersionedView < View
      DEFAULT_VERSION = :default

      attr_reader :working

      def initialize(versions)
        @versions = versions
        determine_working_version
      end

      def initialize_copy(_)
        super

        @versions = @versions.map(&:dup)
      end

      def version(version)
        version_named(version)
      end

      def use(version)
        # TODO: handle no version found
        set_version(version_named(version))
      end

      def transform(data)
        insertable = self

        Array.ensure(data).each do |object|
          versioned_view = self.dup

          yield versioned_view, object if block_given?
          versioned_view.working.transform(object)

          insertable.after(versioned_view)
          insertable = versioned_view
        end

        @versions.each(&:remove)

        self
      end

      protected

      def determine_working_version
        set_version(default_version || first_version)
      end

      def set_version(view)
        @object = view.object
        @working = view
        @version = view.version
        @attributes = view.attributes
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
