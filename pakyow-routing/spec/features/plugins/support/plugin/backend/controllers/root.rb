controller :root, "/test-plugin" do
  default

  get "/endpoint/:name" do
    send path(params[:name])
  end

  get "/app_endpoint/:name" do
    send parent_app.endpoints.path(params[:name])
  end

  get "/render/explicit" do
    render "/test-plugin/render"
  end

  get "/render/implicit" do
  end

  get "/parent-app" do
    send parent_app.class.name
  end

  get "/helpers" do
    send test_helper
  end
end
