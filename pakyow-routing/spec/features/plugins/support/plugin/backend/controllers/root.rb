controller :root, "/test-plugin" do
  default

  get "/endpoint/:name" do
    send path(params[:name])
  end

  get "/app_endpoint/:name" do
    send app.parent.endpoints.path(params[:name])
  end

  get "/render/explicit" do
    render "/test-plugin/render"
  end

  get "/render/implicit" do
  end

  get "/parent-app" do
    send app.parent.class.name
  end

  get "/helpers" do
    send test_helper
  end
end
