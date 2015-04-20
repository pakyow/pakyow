#TODO replace w/ require 'pakyow'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-support/lib/pakyow-support'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-core/lib/pakyow-core'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-presenter/lib/pakyow-presenter'
require '/users/bryanp/code/pakyow/libs/pakyow/pakyow-mailer/lib/pakyow-mailer'

require_relative 'test_help/ext/request'
require_relative 'test_help/ext/response'

require_relative 'test_help/mocks/presenter_mock'
require_relative 'test_help/mocks/status_mock'

require_relative 'test_help/observables/observable_presenter'
require_relative 'test_help/observables/observable_view'

require_relative 'test_help/helpers'
require_relative 'test_help/simulator'
require_relative 'test_help/simulation'

module Pakyow
  module TestHelp
    def self.setup
      Pakyow::App.stage :test

      Pakyow::App.after :match do
        @presenter = Pakyow::TestHelp::ObservablePresenter.new(@presenter)
      end
    end
  end
end
