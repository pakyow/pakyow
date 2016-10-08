Pakyow::Config.register :app do |config|

  config.opt :name, 'pakyow'

  # if true, errors are displayed in the browser
  config.opt :errors_in_browser, true

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

  # whether or not pakyow should serve static files
  config.opt :static, true

  # stores the path to the app definition
  config.opt :path, -> { Pakyow::App.path }

  # if true, issues a 301 redirect to the www version
  config.opt :enforce_www, true

  # stores the envs an app is run in
  config.opt :loaded_envs

  # the console object to use in `pakyow console`
  config.opt :console_object, -> { IRB }
end.env :prototype do |opts|
  opts.ignore_routes = true
end.env :test do |opts|
  opts.errors_in_browser = false
end.env :production do |opts|
  opts.errors_in_browser = false
end
