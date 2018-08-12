# frozen_string_literal: true

require "redcarpet"

require "pakyow/framework"

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

        connection.app.subclass(:Renderer).perform_for_connection(connection)
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

    module ImplicitRendering
      extend Support::Pipelined::Pipeline

      action :setup_for_implicit_rendering

      protected

      def setup_for_implicit_rendering(connection)
        connection.on :finalize do
          app.subclass(:Renderer).perform_for_connection(self)
        end
      end
    end

    class Framework < Pakyow::Framework(:presenter)
      def boot
        require "pakyow/presenter/presentable_error"

        app.class_eval do
          subclass!(Renderer)

          subclass? :Connection do
            include Renderable
          end

          stateful :templates, Templates
          stateful :presenter, Presenter
          stateful :binder, Binder
          stateful :processor, Processor

          aspect :presenters
          aspect :binders

          helper RenderHelpers

          subclass? :Controller do
            include_pipeline ImplicitRendering
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

                expose :"pw_error", error
                render "/development/500"
              else
                render "/500"
              end
            end
          end

          binder :"pw_error" do
            def message
              safe(markdown.render(object.message))
            end

            def details
              safe(markdown.render(object.details))
            end

            def backtrace
              safe(object.backtrace.to_a.join("<br>"))
            end

            def link
              part :href do
                object.url
              end

              part :content do
                object.url
              end
            end

            private

            def markdown
              @markdown ||= Redcarpet::Markdown.new(
                Redcarpet::Render::HTML.new({})
              )
            end
          end
        end
      end
    end
  end
end
