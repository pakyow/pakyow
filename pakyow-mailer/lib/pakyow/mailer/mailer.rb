# frozen_string_literal: true

require "pakyow/mailer/plaintext"

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
          catch :halt do
            @renderer.perform
          end

          process(@renderer.connection.response.body.read, @config.default_content_type)
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

        Array(recipient).map { |recipient|
          deliverable_mail = mail.dup
          deliverable_mail.to = recipient
          deliverable_mail.deliver.tap do |delivered_mail|
            if @config.log_outgoing
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
            processed_content[:text] = Plaintext.convert_to_text(
              (document.at_css("body") || document).to_xml
            )

            # TODO: inline css
            processed_content[:html] = content
          else
            processed_content[:text] = content
          end
        end
      end

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

      def rpad(message, offset = 0)
        message + " " * (76 + offset - message.length)
      end
    end
  end
end
