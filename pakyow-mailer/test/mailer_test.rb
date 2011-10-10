require 'helper'

class MailerTest < Test::Unit::TestCase
  def setup
    TestApplication.stage(:testing)
  end
  
  def test_mailer_is_properly_initialized
    m = self.mailer
    
    assert_equal(Mail::Message, m.message.class)
    assert_equal(View, m.view.class)
  end
  
  def test_setting_view_sets_message_body
    m = self.mailer(true)
    
    assert_equal(File.open("test/views/test_message.email/main.html", "rb").read, m.view.to_html)
  end
  
  def test_subject_is_set
    subject = 'Foo'
    
    m = self.mailer
    m.deliver_to('bogus@test.com', subject)
    
    assert_equal(subject, m.message.subject)
  end
  
  def test_can_send_to_one_recipient
    r = 'bogus@test.com'
    
    m = self.mailer
    m.deliver_to(r)
    
    assert(m.delivered_to.include?(r))
  end
  
  def test_can_send_to_multiple_recipients
    rs = ['bogus1@test.com', 'bogus2@test.com']
    
    m = self.mailer
    m.deliver_to(rs)
    
    rs.each do |r|
      assert(m.delivered_to.include?(r))
    end
  end
  
  def mailer(partial = false)
    path = "test_message"
    path = File.join(path, "main.html") if partial
    
    TestMailer.new(path)
  end
end
