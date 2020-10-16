helper :context do
  def test_helper
    "test_helper: #{connection.app.class}"
  end

  def test_context
    "test_context: #{some_action}"
  end
end
