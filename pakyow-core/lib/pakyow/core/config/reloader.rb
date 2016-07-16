Pakyow::Config.register :reloader do |config|

  # if true, the app will be reloaded on every request
  config.opt :enabled, true

end.env :development do |opts|
  opts.enabled = true
end.env :production do |opts|
  opts.enabled = false
end
