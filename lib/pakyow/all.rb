%w(
  support
  core
  presenter
  mailer
  realtime
).each do |lib|
  require "pakyow/#{lib}"
end
