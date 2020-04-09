# frozen_string_literal: true

require "cgi"

require "redcarpet"

require "pakyow/support/deep_dup"
require "pakyow/support/extension"
require "pakyow/support/safe_string"

require "pakyow/error"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module ErrorRendering
          extend Support::Extension

          using Support::DeepDup

          class << self
            # @api private
            def render_error(error, connection)
              if connection.format == :html
                if Pakyow.env?(:production)
                  if connection.app.rescued?
                    connection.body = build_error_view("/500").to_html
                    connection.halt
                  else
                    connection.render "/500"
                  end
                else
                  unless error.is_a?(Pakyow::Error)
                    error = Pakyow::Error.build(error)
                  end

                  if connection.app.rescued?
                    error_view = build_error_view("/development/500")
                    error_binder = connection.app.binders(:pw_error).new(error, app: connection.app)
                    error_view.find(:pw_error).bind(error_binder)

                    connection.body = error_view.to_html
                    connection.halt
                  else
                    connection.set :pw_error, error

                    connection.render "/development/500"
                  end
                end
              end
            end

            # @api private
            def error_templates
              @__error_templates ||= Pakyow::Presenter::Templates.new(
                :errors, File.join(File.expand_path("../../../../", __FILE__), "views", "errors")
              )
            end

            # @api private
            def build_error_view(view_path)
              info = error_templates.info(view_path).deep_dup
              info[:layout].build(info[:page])
            end
          end

          apply_extension do
            if ancestors.include?(Application)
              after "load.presenter" do
                templates << ErrorRendering.error_templates
              end

              after "rescue" do
                unless templates.definitions.any? { |definition| definition.name == :errors }
                  templates << ErrorRendering.error_templates
                end
              end
            end

            handle 404 do |connection:|
              if connection.format == :html
                connection.render "/404"
              end
            end

            handle 500 do |connection:|
              if error = connection.error
                ErrorRendering.render_error(error, connection)
              end
            end

            handle Pakyow::Presenter::UnknownPage, as: 404 do |error, connection:|
              if Pakyow.env?(:production)
                trigger 404, connection: connection
              else
                ErrorRendering.render_error(connection.error, connection)
              end
            end

            handle Pakyow::Presenter::ImplicitRenderingError, as: 404 do |error, connection:|
              if Pakyow.env?(:production)
                trigger 404, connection: connection
              else
                ErrorRendering.render_error(connection.error, connection)
              end
            end

            binder :pw_error do
              # Include this explicitly since helpers might not load during rescue.
              #
              include Support::SafeStringHelpers

              def message
                html_safe(markdown.render(format(object.message)))
              end

              def contextual_message
                if object.respond_to?(:contextual_message)
                  html_safe(markdown.render(format(object.contextual_message)))
                else
                  nil
                end
              end

              def details
                html_safe(markdown.render(format(object.details)))
              end

              def backtrace
                html_safe(object.condensed_backtrace.to_a.map { |line|
                  CGI.escape_html(line)
                }.join("<br>"))
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

              def format(string)
                string = string.dup

                # Replace `foo' with `foo` to render as inline code.
                #
                string.dup.scan(/`([^']*)'/).each do |match|
                  string.gsub!("`#{match[0]}'", "`#{match[0]}`")
                end

                # Format object references as inline code.
                #
                string.dup.scan(/#<(.*)>/).each do |match|
                  string.gsub!("#<#{match[0]}>", "`#<#{match[0]}>`")
                end

                string
              end
            end
          end
        end
      end
    end
  end
end
