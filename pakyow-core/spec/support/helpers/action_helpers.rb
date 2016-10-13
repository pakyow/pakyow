module ActionHelpers
  def reset
    Pakyow.setup(env: :test).run
    @context = Pakyow::CallContext.new(mock_request.env)
  end

  def app
    Pakyow::App
  end
end
