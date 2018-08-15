# frozen_string_literal: true

require "cgi"

require "redcarpet"

require "pakyow/support/extension"

require "pakyow/error"

module Pakyow
  module Presenter
    module Behavior
      module ErrorRendering
        extend Support::Extension

        apply_extension do
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
                  Pakyow::Error.build(connection.error)
                end

                expose :pw_error, error
                render "/development/500"
              else
                render "/500"
              end
            end
          end

          binder :pw_error do
            def message
              message = object.message.dup

              # Replace `foo' with `foo` to render as inline code.
              #
              message.dup.scan(/`(.*)'/).each do |match|
                message.gsub!("`#{match[0]}'", "`#{match[0]}`")
              end

              # Format object references as inline code.
              #
              message.dup.scan(/#<(.*)>/).each do |match|
                message.gsub!("#<#{match[0]}>", "`#<#{match[0]}>`")
              end

              safe(markdown.render(message))
            end

            def details
              safe(markdown.render(object.details))
            end

            def backtrace
              safe(object.condensed_backtrace.to_a.map { |line|
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
          end
        end
      end
    end
  end
end
