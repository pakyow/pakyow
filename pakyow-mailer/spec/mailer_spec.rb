require 'support/helper'

describe 'Mailer' do
  before do
    Pakyow::App.stage(:test)
  end

  let :mailer do
    TestMailer.mailer('test_message')
  end

  it 'is properly initialized' do
    expect(mailer.message).to be_a Mail::Message
    expect(mailer.view).to be_a Pakyow::Presenter::ViewContext
  end

  it 'view sets message body' do
    expect(mailer.view.doc.text.strip).to eq 'Hello From Pakyow Mailer'
  end

  it 'subject is set' do
    subject = 'Foo'
    mailer.deliver_to('bogus@test.com', subject)
    expect(mailer.message.subject).to eq subject
  end

  it 'can send to one recipient' do
    r = 'bogus@test.com'
    mailer.deliver_to(r)
    expect(mailer.delivered_to).to include r
  end

  it 'can send to multiple recipients' do
    rs = ['bogus1@test.com', 'bogus2@test.com']
    mailer.deliver_to(rs)
    rs.each do |r|
      expect(mailer.delivered_to).to include r
    end
  end
end
