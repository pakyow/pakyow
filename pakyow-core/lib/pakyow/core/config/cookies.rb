Pakyow::Config.register :cookies do |config|
  config.opt :path, '/'
  config.opt :expiration, -> { Time.now + 60 * 60 * 24 * 7 }
end
