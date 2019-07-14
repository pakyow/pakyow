# frozen_string_literal: true

require "oga"

require "pakyow/mailer/plaintext"
require "pakyow/mailer/style_inliner"

module Pakyow
  module Mailer
    class Mailer
      def initialize(config:, renderer: nil, logger: Pakyow.logger)
        @config, @renderer, @logger = config, renderer, logger
      end

      def deliver_to(recipient, subject: nil, sender: nil, content: nil, type: nil)
        processed_content = if content
          process(content, type || "text/plain")
        elsif @renderer
          process(@renderer.perform, @config.default_content_type)
        else
          {}
        end

        html = processed_content[:html]
        text = processed_content[:text]

        mail = Mail.new
        mail.from = sender || @config.default_sender
        mail.content_type = type || @config.default_content_type
        mail.delivery_method(@config.delivery_method, @config.delivery_options)

        if html.nil?
          mail.body = text
        else
          encoding = @config.encoding

          mail.html_part do
            content_type "text/html; charset=" + encoding
            body html
          end

          mail.text_part do
            content_type "text/plain; charset=" + encoding
            body text
          end
        end

        if subject
          mail.subject = subject
        end

        Array(recipient).map { |to|
          deliverable_mail = mail.dup
          deliverable_mail.to = to
          deliverable_mail.deliver.tap do |delivered_mail|
            unless @config.silent
              log_outgoing(delivered_mail)
            end
          end
        }
      end

      private

      def process(content, content_type)
        {}.tap do |processed_content|
          if content_type.include?("text/html")
            document = Oga.parse_html(content)
            mailable_document = document.at_css("body") || document

            processed_content[:text] = Plaintext.convert_to_text(
              mailable_document.to_xml
            )

            stylesheets = if @renderer
              @renderer.app.packs(@renderer.presenter.view).select(&:stylesheets?).map(&:stylesheets)
            else
              []
            end

            processed_content[:html] = StyleInliner.new(
              mailable_document,
              stylesheets: stylesheets
            ).inlined
          else
            processed_content[:text] = content
          end
        end
      end

      # @api private
      def log_outgoing(delivered_mail)
        message = String.new
        message << "┌──────────────────────────────────────────────────────────────────────────────┐\n"
        message << "│ Subject: #{rpad(delivered_mail.subject, -9)} │\n"

        if plaintext = delivered_mail.body.parts.find { |part|
             part.content_type.include?("text/plain")
           }

          message << "├──────────────────────────────────────────────────────────────────────────────┤\n"

          plaintext.body.to_s.split("\n").each do |line|
            message << "│ #{rpad(line)} │\n"
          end
        end

        message << "├──────────────────────────────────────────────────────────────────────────────┤\n"
        message << "│ → #{rpad(delivered_mail.to.join(", "), -2)} │\n"
        message << "└──────────────────────────────────────────────────────────────────────────────┘\n"
        @logger.debug message
      end

      # @api private
      def rpad(message, offset = 0)
        message = message.to_s
        message + " " * (76 + offset - message.length)
      end
    end
  end
end
