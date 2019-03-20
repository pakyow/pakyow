# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/extension"

require "pakyow/presenter/errors"
require "pakyow/presenter/templates"
require "pakyow/presenter/view_builder/state"

module Pakyow
  module Presenter
    module Behavior
      module Building
        extend Support::Extension

        apply_extension do
          extend Support::DeepFreeze
          unfreezable :built_views

          after :initialize do
            @built_views = {}
            @view_builder = isolated(:ViewBuilder).new
          end
        end

        using Support::DeepDup
        using Support::DeepFreeze

        def view(templates_path, copy: true)
          view = @built_views[templates_path] || build_and_cache_view(templates_path)
          view = view.dup if copy
          view
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

        def build_and_cache_view(templates_path)
          cache_view(build_view(templates_path), templates_path)
        end

        def build_view(templates_path)
          unless info = find_info(templates_path)
            error = UnknownPage.new("No view at path `#{templates_path}'")
            error.context = templates_path
            raise error
          end

          info = info.deep_dup

          state = ViewBuilder::State.new(
            app: self,
            view: info[:layout].build(info[:page]).tap { |view|
              view.mixin(info[:partials])
            },
            path: templates_path
          )

          @view_builder.call(state)

          state.view
        end

        UNRETAINED_SIGNIFICANCE = %i(container partial template).freeze

        def cache_view(view, templates_path)
          view.object.collapse(
            *(StringDoc.significant_types.keys - UNRETAINED_SIGNIFICANCE)
          )

          view.object.remove_empty_nodes

          @built_views[templates_path] = view.deep_freeze
        end
      end
    end
  end
end
