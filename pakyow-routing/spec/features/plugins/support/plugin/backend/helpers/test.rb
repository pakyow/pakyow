helper :test do
  def test
    "#{app.class.plugin_name}(#{app.class.__object_name.namespace.parts.last})"
  end
end
