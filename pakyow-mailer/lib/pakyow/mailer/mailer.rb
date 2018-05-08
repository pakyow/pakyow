# frozen_string_literal: true

require "pakyow/mailer/plaintext"

module Pakyow
  module Mailer
    class Mailer
      def initialize(config:, renderer: nil)
        @config, @renderer = config, renderer
      end

      def deliver_to(recipient, subject: nil, sender: nil, content: nil, type: nil)
        processed_content = if content
          process(content, type || "text/plain")
        else
          catch :halt do
            @renderer.perform
          end

          process(@renderer.connection.response.body.read, @config.default_content_type)
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
            body text
          end
        end

        if subject
          mail.subject = subject
        end

        Array(recipient).map { |recipient|
          deliverable_mail = mail.dup
          deliverable_mail.to = recipient
          deliverable_mail.deliver
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
    end
  end
end
