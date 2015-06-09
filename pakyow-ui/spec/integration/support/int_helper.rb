require_relative '../../spec_helper'
require_relative '../../../lib/pakyow-ui'

Pakyow::App.define do
  configure :test do
    presenter.view_stores[:default] = 'spec/integration/support/app/views'
  end
end
