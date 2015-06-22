require 'support/helper'

describe 'Mailer' do
  before do
    Pakyow::App.stage(:test)
  end

  it 'is properly initialized' do
    m = TestMailer.mailer

    expect(m.message).to be_a Mail::Message
    expect(m.view).to be_a Pakyow::Presenter::View
  end

  it 'view sets message body' do
    m = TestMailer.mailer
    expect(m.view.doc.text.strip).to eq 'Hello From Pakyow Mailer'
  end

  it 'subject is set' do
    subject = 'Foo'

    m = TestMailer.mailer
    m.deliver_to('bogus@test.com', subject)

    expect(m.message.subject).to eq subject
  end

  it 'can send to one recipient' do
    r = 'bogus@test.com'

    m = TestMailer.mailer
    m.deliver_to(r)

    expect(m.delivered_to).to include r
  end

  it 'can send to multiple recipients' do
    rs = ['bogus1@test.com', 'bogus2@test.com']

    m = TestMailer.mailer
    m.deliver_to(rs)

    rs.each do |r|
      expect(m.delivered_to).to include r
    end
  end
end
