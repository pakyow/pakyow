# frozen_string_literal: true

require "string_doc"

require "pakyow/support/deep_dup"

require "pakyow/presenter/errors"
require "pakyow/presenter/view"

require "pakyow/presenter/composers/view"

module Pakyow
  module Presenter
    module Composers
      # @api private
      class Component < View
        using Support::DeepDup

        attr_reader :component_path

        def initialize(view_path, component_path, app:, labels: {})
          super(view_path, app: app)
          @component_path = component_path
          @labels = labels
        end

        def key
          @view_path + "::" + @component_path.join("::")
        end

        def post_process(view)
          self.class.follow_path(@component_path, view)
        end

        def finalize(view)
          if @labels.any?
            if view.frozen?
              view = view.soft_copy
            end

            @labels.each_pair do |key, value|
              view.object.set_label(key, value)
            end
          end

          view
        end

        def marshal_dump
          {
            app: @app,
            view_path: @view_path,
            component_path: @component_path
          }
        end

        def marshal_load(state)
          @labels = {}
          state.each do |key, value|
            instance_variable_set(:"@#{key}", value)
          end
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
