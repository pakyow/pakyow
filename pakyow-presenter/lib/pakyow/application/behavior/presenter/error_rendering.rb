# frozen_string_literal: true

require "cgi"

require "redcarpet"

require "pakyow/support/bindable"
require "pakyow/support/extension"

require "pakyow/error"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module ErrorRendering
          extend Support::Extension

          # @api private
          #
          def self.render_error(error, connection)
            if connection.format == :html
              if Pakyow.env?(:production)
                connection.render "/500"
              else
                unless error.is_a?(Pakyow::Error)
                  error = Pakyow::Error.build(error)
                end

                error.extend Support::Bindable
                connection.set :pw_error, error
                connection.render "/development/500"
              end
            end
          end

          apply_extension do
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
