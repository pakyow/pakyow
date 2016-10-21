require 'support/helper'

RSpec.describe 'using mutators in a mailer' do
  before do
    Pakyow::App.stage(:test)
  end

  let :mailer do
    TestMailer.mailer('mutator')
  end

  let :view do
    mailer.view
  end

  let :data do
    { bar: 'baz' }
  end

  it 'mutates the mail view' do
    view.scope(:foo).mutate(:bar, with: data)
    expect(view.scope(:foo).prop(:bar).first.text).to eq(data[:bar])
  end
end
