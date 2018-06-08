# frozen_string_literal: true

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "redcarpet"
end

require "pakyow/core/framework"

module Pakyow
  module Presenter
    class AutoRender
      def initialize(_)
      end

      def call(connection)
        unless connection.env[Rack::RACK_LOGGER]
          connection.env[Rack::RACK_LOGGER] = Pakyow::Logger::RequestLogger.new(:http)
          connection.logger.prologue(connection.env)
        end

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

            setting :embed_authenticity_token, true
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

            state_for(:templates) << Templates.new(:errors, File.join(File.expand_path("../../", __FILE__), "views", "errors"))
          end

          handle 404 do
            respond_to :html do
              render "/404"
            end
          end

          handle 500 do
            respond_to :html do
              if Pakyow.env?(:development) || Pakyow.env?(:prototype)
                error = if connection.error.is_a?(Pakyow::Error)
                  connection.error
                else
                  Pakyow.build_error(connection.error, Pakyow::Error)
                end

                expose :error, error
                render "/development/500"
              else
                render "/500"
              end
            end
          end

          presenter "/development/500" do
            perform do
              if error.is_a?(Pakyow::Error)
                self.title = error.name
                markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
                find(:error).use(:friendly)
                find(:error).present(
                  name: error.name,
                  message: safe(markdown.render(error.message)),
                  details: safe(markdown.render(error.details)),
                  backtrace: safe(error.backtrace.to_a.join("<br>"))
                )
              else
                self.title = error.class
                find(:error).use(:other)
                find(:error).present(
                  name: error.class,
                  message: error.to_s,
                  backtrace: safe(error.backtrace.join("<br>"))
                )
              end
            end
          end
        end
      end
    end
  end
end
