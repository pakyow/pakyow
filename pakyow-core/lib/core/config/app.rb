Pakyow::Config.register :app do |config|
  # if true, the app will be reloaded on every request
  config.opt :auto_reload

  # if true, errors are displayed in the browser
  config.opt :errors_in_browser

  # the location of the app's root directory
  config.opt :root, File.dirname('')

  # the location of the app's resources
  config.opt :resources, -> {
    @resources ||= {
      default: File.join(root, 'public')
    }
  }

  # the location of the app's source code
  config.opt :src_dir, -> { File.join(root, 'app', 'lib') }

  # the environment to run in, if one isn't provided
  config.opt :default_environment, :development

  # the default action to use for routing
  config.opt :default_action, :index

  # if true, all routes are ignored
  config.opt :ignore_routes, false

  # whether or not pakyow should log to stdout
  config.opt :log_output, true

  # whether or not pakyow should write to a log
  config.opt :log, true

  # whether or not pakyow should serve static files
  config.opt :static, true

  # stores the path to the app definition
  config.opt :path, -> { Pakyow::App.path }

  # stores the envs an app is run in
  config.opt :loaded_envs
end.env :development do |opts|
  opts.auto_reload = true
  opts.errors_in_browser = true
  opts.static = true
end.env :production do |opts|
  opts.auto_reload = false
  opts.errors_in_browser = false
  opts.log_output = false
  opts.static = true
end
