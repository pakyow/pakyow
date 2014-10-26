module Pakyow
  class Mailer
    attr_accessor :view, :message, :processed

    def initialize(view_path, view_store)
      @view = view_store.view(view_path)

      @message               = Mail.new
      @message.from          = Config.mailer.default_sender
      @message.content_type  = Config.mailer.default_content_type
      @message.delivery_method(Config.mailer.delivery_method, Config.mailer.delivery_options)
    end

    def deliver_to(recipient, subject = nil)
      html = content(:html)
      text = content(:text)

      @message.html_part do
        content_type 'text/html; charset=' + Config.mailer.encoding
        body html
      end

      @message.text_part do
        body text
      end

      @message.subject = subject if subject

      Array(recipient).each {|r| deliver(r)}
    end

    def content(type = :html)
      return process[type]
    end

    protected

    def process
      unless @processed
        @premailer = Premailer.new(view.to_html, with_html_string: true, input_encoding: Config.mailer.encoding)

        @premailer.warnings.each do |w|
          Pakyow.logger.warn "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
        end

        @processed_content = {
          html: @premailer.to_inline_css,
          text: @premailer.to_plain_text,
        }

        @processed = true
      end

      return @processed_content
    end

    def deliver(recipient)
      @message.to = recipient
      @message.deliver
    end
  end
end
