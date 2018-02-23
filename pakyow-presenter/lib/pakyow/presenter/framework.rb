# frozen_string_literal: true

require "pakyow/core/framework"

module Pakyow
  module Presenter
    class AutoRender
      def initialize(_)
      end

      def call(connection)
        connection.app.class.const_get(:Renderer).perform_for_connection(connection)
      end
    end

    module Renderable
      def self.included(base)
        base.prepend Initializer
      end

      def rendered
        @rendered = true
        halt
      end

      def rendered?
        @rendered == true
      end

      module Initializer
        def initialize(*args)
          @rendered = false
          super
        end
      end
    end

    class Pakyow::Connection
      include Renderable
    end

    module ImplicitRendering
      extend Support::Pipelined::Pipeline

      action :setup_for_implicit_rendering

      protected

      def setup_for_implicit_rendering(connection)
        connection.on :finalize do
          app.class.const_get(:Renderer).perform_for_connection(self)
        end
      end
    end

    class Framework < Pakyow::Framework(:presenter)
      def boot
        # We create a subclass because other frameworks could extend its behavior. Since frameworks
        # are loaded at the application level, we don't want one application affecting another.
        subclass(Renderer)

        app.class_eval do
          stateful :templates, Templates
          stateful :presenter, ViewPresenter
          stateful :binder, Binder
          stateful :processor, Processor

          aspect :presenters
          aspect :binders

          helper RenderHelpers

          if const_defined?(:Controller)
            const_get(:Controller).include_pipeline ImplicitRendering
          end

          settings_for :presenter do
            setting :path do
              File.join(config.root, "frontend")
            end
          end

          after :load do
            ([:html] + self.class.state[:processor].instances.map(&:extensions).flatten).uniq.each do |extension|
              config.process.watched_paths << File.join(config.presenter.path, "**/*.#{extension}")
            end
          end

          after :initialize do
            state_for(:templates) << Templates.new(
              :default,
              config.presenter.path,
              processor: ProcessorCaller.new(
                self.class.state[:processor].instances
              )
            )

            # if environment == :development
            #   app_class.handle MissingView, as: 500 do
            #     respond_to :html do
            #       render "/missing_view"
            #     end
            #   end

            #   app_class.templates << Templates.new(:errors, File.join(File.expand_path("../../", __FILE__), "views", "errors"))

            #   # TODO: define view objects to render built-in errors
            # end

            # TODO: the following handlers override the ones defined on the app
            # ideally global handlers could coexist (e.g. handle bugsnag, then present error page)
            # perhaps by executing all of 'em at once until halted or all called; feels consistent with
            # how multiple handlers are called in non-global cases; though load order would be important

            # app_class.handle 404 do
            #   respond_to :html do
            #     render "/404"
            #   end
            # end

            # app_class.handle 500 do
            #   respond_to :html do
            #     render "/500"
            #   end
            # end
          end
        end
      end
    end
  end
end
