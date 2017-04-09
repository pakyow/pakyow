Pakyow::App.router do
  default do
    render "/" do |view|
      view.title = "hello world"
    end
  end
end
