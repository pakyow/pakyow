$global_config_was_executed = false
$env_overwrites_global_config = nil

Pakyow::App.define do
  configure :global do
    $global_config_was_executed = true
    $env_overwrites_global_config = false
    server.handler = Class.new { def self.run(*args); end }
  end

  configure :test do
    $env_overwrites_global_config = true
    app.src_dir = File.join(Dir.pwd, "spec", "support", "helpers", "loader")
    app.foo = :bar
  end

  routes :redirect do
    get :redirect_route, "/redirect" do
    end
  end
end
