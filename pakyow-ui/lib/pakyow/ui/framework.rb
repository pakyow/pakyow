# frozen_string_literal: true

require "concurrent/executor/thread_pool_executor"

require "pakyow/framework"

require "pakyow/app/helpers/ui"

require "pakyow/app/behavior/ui/recording"
require "pakyow/app/behavior/ui/rendering"
require "pakyow/app/behavior/ui/timeouts"

require "pakyow/presenter/renderer/behavior/ui/install_transforms"

module Pakyow
  module UI
    class Framework < Pakyow::Framework(:ui)
      # @api private
      module PresenterForContext
        def presenter_for_context(presenter_class, context)
          if context.presentables.include?(:__ui_transform)
            instance = find_ui_presenter_for(presenter_class).new(
              context.view, app: context.app, presentables: context.presentables
            )

            instance.instance_variable_set(:@calls, context.calls)
            instance
          else
            super
          end
        end
      end

      def boot
        object.class_eval do
          register_helper :passive, App::Helpers::UI

          include App::Behavior::UI::Recording
          include App::Behavior::UI::Rendering
          include App::Behavior::UI::Timeouts

          isolated :Renderer do
            include Presenter::Renderer::Behavior::UI::InstallTransforms
          end

          prepend PresenterForContext

          ui_renderer = Class.new(isolated(:Renderer)) do
            def marshal_load(state)
              deserialize(state)
              @presenter_class = @app.find_ui_presenter_for(@presenter_class)
              initialize_presenter
            end

            def perform(*)
              @presenter.to_html
            end
          end

          # Delete the render_components build step since ui will not be invoking the component.
          #
          ui_renderer.__build_fns.delete_if { |fn|
            fn.source_location[0].end_with?("render_components.rb")
          }

          unless const_defined?(:UIRenderer, false)
            const_set(:UIRenderer, ui_renderer)
          end

          after "initialize" do
            config.data.subscriptions.version = config.version
          end

          # @api private
          attr_reader :ui_executor
          unfreezable :ui_executor

          after "initialize" do
            @ui_executor = Concurrent::ThreadPoolExecutor.new(
              auto_terminate: false,
              min_threads: 1,
              max_threads: 10,
              max_queue: 0
            )
          end
        end
      end
    end
  end
end
