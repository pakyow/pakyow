# frozen_string_literal: true

require "string_doc"

require "pakyow/support/deep_dup"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/errors"

module Pakyow
  module Presenter
    module Composers
      class View
        using Support::DeepDup
        using Support::Refinements::String::Normalization

        attr_reader :view_path

        UNRETAINED_SIGNIFICANCE = %i(container partial template).freeze

        def initialize(view_path)
          @view_path = String.normalize_path(view_path)
        end

        def key
          @view_path
        end

        def view(app:)
          unless info = app.view_info_for_path(@view_path)
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
            *(StringDoc.significant_types.keys - UNRETAINED_SIGNIFICANCE)
          )

          # Empty nodes are removed as another render-time optimization leading to fewer operations.
          #
          view.object.remove_empty_nodes

          view
        end
      end
    end
  end
end
