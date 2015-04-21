require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-mailer'

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
