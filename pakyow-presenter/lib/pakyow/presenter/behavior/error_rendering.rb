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

        def self.render_error(error, context)
          context.respond_to :html do
            if Pakyow.env?(:production)
              context.render "/500"
            else
              unless error.is_a?(Pakyow::Error)
                error = Pakyow::Error.build(error)
              end

              context.expose :pw_error, error
              context.render "/development/500"
            end
          end
        end

        apply_extension do
          handle 404 do
            respond_to :html do
              render "/404"
            end
          end

          handle 500 do |error|
            ErrorRendering.render_error(error, self)
          end

          handle UnknownPage, as: 404 do |error|
            if Pakyow.env?(:production)
              trigger 404
            else
              ErrorRendering.render_error(error, self)
            end
          end

          handle ImplicitRenderingError, as: 404 do |error|
            if Pakyow.env?(:production)
              trigger 404
            else
              ErrorRendering.render_error(error, self)
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
