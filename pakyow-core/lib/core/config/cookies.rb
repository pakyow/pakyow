Pakyow::Config.register(:cookies) { |config|
  config.opt :path, '/'
  config.opt :expiration, lambda { Time.now + 60 * 60 * 24 * 7 }
}
