controller :root, "/test-plugin" do
  get "/render/explicit" do
    render "/test-plugin/render"
  end

  get "/render/implicit" do
  end

  get "/render/app" do
    render "/app-only"
  end
end
