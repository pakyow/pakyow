module ActionHelpers
  def reset
    app.run(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
  end

  def app
    Pakyow::App
  end
end
