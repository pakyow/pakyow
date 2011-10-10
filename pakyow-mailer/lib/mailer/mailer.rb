module Pakyow
  class Mailer
    attr_accessor :view, :mail, :delivery_method, :delivery_options
  
    def initialize(view_path)
      @delivery_method  = Configuration::Base.mailer.delivery_method
      @delivery_options = Configuration::Base.mailer.delivery_options
      
      @view = Pakyow.app.presenter.view_for_full_view_path(view_path, true)
      
      @mail               = Mail.new
      @mail.from          = Configuration::Base.mailer.default_sender
      @mail.content_type  = Configuration::Base.mailer.default_content_type
    end
    
    def deliver_to(recipient, subject = nil)
      @mail.to      = recipient
      @mail.body    = self.view.to_html
      @mail.subject = subject if subject
      
      if recipient.is_a?(Array)
        recipient.each {|r| deliver(r)}
      else
        deliver(recipient)
      end
    end
    
    protected
  
    def deliver(recipient)
      mail.delivery_method(@delivery_method, @delivery_options)
      mail.deliver
    end
  end
end
