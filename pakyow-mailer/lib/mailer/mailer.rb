#TODO attachments
#TODO multipart

module Pakyow
  class Mailer
    attr_accessor :subject, :sender, :content_type, :delivery_method, :delivery_options, :view
  
    def initialize(*args)
      @sender           = Configuration::Base.mailer.default_sender
      @content_type     = Configuration::Base.mailer.default_content_type
      @delivery_method  = Configuration::Base.mailer.delivery_method
      @delivery_options = Configuration::Base.mailer.delivery_options
      @files            = []
      
      @view = Pakyow::Presenter::View.new(*args)
    end
  
    def deliver_to(recipient, subject = nil)
      @subject  = subject if subject
      @body     = self.view.to_html
      
      if recipient.is_a?(Array)
        recipient.each {|r| deliver(r)}
      else
        deliver(recipient)
      end
    end
  
    # def add_file(opts)
    #   @files << opts
    # end
    
    protected
  
    def deliver(recipient)
      mail = Mail.new
      mail.from = @sender
      mail.to = recipient
      mail.subject = @subject
      mail.content_type = @content_type
      mail.body = @body
      
      # @files.each do |file_opts|
      #   mail.add_file file_opts
      # end
    
      mail.delivery_method(@delivery_method, @delivery_options)
      mail.deliver
    end
  end
end
