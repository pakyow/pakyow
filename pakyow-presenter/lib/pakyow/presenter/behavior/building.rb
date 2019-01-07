# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/errors"
require "pakyow/presenter/templates"

module Pakyow
  module Presenter
    module Behavior
      module Building
        extend Support::Extension

        def build_view(templates_path, layout: nil)
          unless info = find_info(templates_path)
            error = UnknownPage.new("No view at path `#{templates_path}'")
            error.context = templates_path
            raise error
          end

          # Finds a matching layout across template stores.
          #
          if layout && layout_object = layout_with_name(layout)
            info[:layout] = layout_object.dup
          end

          info[:layout].build(info[:page]).tap do |view|
            view.mixin(info[:partials])
          end
        end

        def view?(templates_path)
          !find_info(templates_path).nil?
        end

        private

        def find_info(path)
          Templates.collapse_path(path) do |collapsed_path|
            if info = info_for_path(collapsed_path)
              return info
            end
          end
        end

        def info_for_path(path)
          state(:templates).lazy.map { |store|
            store.info(path)
          }.find(&:itself)
        end

        def layout_with_name(name)
          state(:templates).lazy.map { |store|
            store.layout(name)
          }.find(&:itself)
        end
      end
    end
  end
end
