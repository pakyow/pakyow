class TestApplication < Pakyow::Application
  configure(:testing) do
    presenter.view_dir = "test/views"
  end
  
  # This keeps the app from actually being run.
  # def self.detect_handler
  #   TestHandler
  # end
end
