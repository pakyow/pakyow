# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Presenter
    class VersionedView < View
      DEFAULT_VERSION = :default

      attr_reader :working

      def initialize(versions)
        @versions = versions
        create_templates
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
        self.versioned_view = version_named(version)
      end

      def transform(data)
        data = Array.ensure(data)

        if data.empty? && empty_view = version_named(:empty)&.dup
          empty_view.object.delete_label(:version)
          empty_view.object.attributes[:"data-empty"] = ""
          after(empty_view)
        else
          insertable = self

          data.each do |object|
            versioned_view = self.dup

            yield versioned_view, object if block_given?
            versioned_view.working.transform(object)
            versioned_view.working.object.delete_label(:version)

            insertable.after(versioned_view)
            insertable = versioned_view
          end
        end

        @versions.each(&:remove)

        self
      end

      protected

      def determine_working_version
        self.versioned_view = default_version || first_version
      end

      def create_templates
        @versions.each do |view|
          template = StringDoc.new("<template data-version=\"#{view.version}\"></template>").nodes.first
          view.attributes.each do |attribute, value|
            next unless attribute.to_s.start_with?("data")
            template.attributes[attribute] = value
          end
          template.append(view.dup)
          view.object.after(template)
        end
      end

      def versioned_view=(view)
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
