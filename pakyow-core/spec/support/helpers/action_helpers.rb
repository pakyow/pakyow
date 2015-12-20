require 'support/helper'
module ActionHelpers
  def reset
    app = app(true)
    app.run(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
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
