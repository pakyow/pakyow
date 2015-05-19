require 'support/helper'
module ActionHelpers
  def reset
    app = app(true)
    app.run(:test)
    Pakyow.app.context = AppContext.new(mock_request, mock_response)
  end

  def app(reset = false)
    if reset
      Pakyow::App.reset
    end

    Pakyow::App
  end

  def app_test_path
    File.join('test', 'support', 'app.rb')
  end
end
