# frozen_string_literal: true

require "pakyow/mailer/plaintext"

module Pakyow
  module Mailer
    class Mailer
      attr_accessor :view, :message, :processed

      def self.from_store(view_path, view_store, context = nil)
        view = view_store.view(view_path)
        new(view: Pakyow::Presenter::ViewContext.new(view, context))
      end

      def initialize(view: nil, content: nil, config: nil)
        @view = view
        @content = content
        @config = config

        @message = Mail.new

        if @config
          @message.from          = config.default_sender
          @message.content_type  = config.default_content_type
          @message.delivery_method(config.delivery_method, config.delivery_options)
        end

        process
      end

      def deliver_to(recipient, subject = nil)
        html = content :html
        text = content :text

        if html.nil?
          @message.body = text
        else
          encoding = @config.encoding
          @message.html_part do
            content_type "text/html; charset=" + encoding
            body html
          end

          @message.text_part do
            body text
          end
        end

        @message.subject = subject if subject

        Array(recipient).each { |r| deliver(r) }
      end

      def content(type = :html)
        @processed_content.fetch(type, nil)
      end

      protected

      def process
        @processed_content = {}

        if @view
          document = Oga.parse_html(@view)
          @processed_content[:text] = Plaintext.convert_to_text(document.at_css("body").to_xml)

          # TODO: inline css
          @processed_content[:html] = @view
        else
          @processed_content[:text] = @content
        end

        @processed_content
      end

      def deliver(recipient)
        @message.to = recipient
        @message.deliver
      end
    end
  end
end
