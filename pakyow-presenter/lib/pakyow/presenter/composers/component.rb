# frozen_string_literal: true

require "string_doc"

require "pakyow/support/deep_dup"

require "pakyow/presenter/errors"
require "pakyow/presenter/view"

require "pakyow/presenter/composers/view"

module Pakyow
  module Presenter
    module Composers
      class Component
        using Support::DeepDup

        attr_reader :view_path, :component_path

        def initialize(view_path, component_path)
          @view_path, @component_path = view_path, component_path
        end

        def key
          @view_path + "::" + @component_path.join("::")
        end

        def view(app:)
          unless info = app.find_view_info(@view_path)
            error = UnknownPage.new("No view at path `#{@view_path}'")
            error.context = @view_path
            raise error
          end

          info = info.deep_dup
          view = info[:layout].build(info[:page]).tap { |view_without_partials|
            view_without_partials.mixin(info[:partials])
          }

          # We collapse built views down to significance that is considered "renderable". This is
          # mostly an optimization, since it lets us collapse some nodes into single strings and
          # reduce the number of operations needed for a render.
          #
          view.object.collapse(
            *(StringDoc.significant_types.keys - View::UNRETAINED_SIGNIFICANCE)
          )

          # Empty nodes are removed as another render-time optimization leading to fewer operations.
          #
          view.object.remove_empty_nodes

          # Follow the path to find the correct component.
          #
          component_node = view.object
          component_path = @component_path.dup
          while step = component_path.shift
            component_node = component_node.find_significant_nodes(:component, descend: true)[step]
          end

          Pakyow::Presenter::View.from_object(component_node)
        end
      end
    end
  end
end
