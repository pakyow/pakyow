# frozen_string_literal: true

require "string_doc"

require "pakyow/support/deep_dup"

require "pakyow/presenter/errors"
require "pakyow/presenter/view"

require "pakyow/presenter/composers/view"

module Pakyow
  module Presenter
    module Composers
      class Component < View
        using Support::DeepDup

        attr_reader :component_path

        def initialize(view_path, component_path)
          super(view_path)
          @component_path = component_path
        end

        def key
          @view_path + "::" + @component_path.join("::")
        end

        def post_process(view)
          self.class.follow_path(@component_path, view)
        end

        class << self
          # Follow the path to find the correct component.
          #
          def follow_path(path, view)
            path = path.dup
            while step = path.shift
              view = view.components[step]
            end

            view
          end
        end
      end
    end
  end
end
