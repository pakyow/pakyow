# require 'rubygems'
# require 'minitest'
# require 'minitest/unit'
# require 'minitest/autorun'
# require 'pp'

# require '../pakyow-support/lib/pakyow-support'
# require '../pakyow-core/lib/pakyow-core'
# require '../pakyow-presenter/lib/pakyow-presenter'
# require '../pakyow-mailer/lib/pakyow-mailer'
# require '../pakyow-realtime/lib/pakyow-realtime'
# require '../pakyow-ui/lib/pakyow-ui'

require 'support/test_mailer'
require 'support/test_application'

class TestMailer
  def self.mailer(view_path)
    from_store(view_path, Pakyow.app.presenter.store)
  end
end
