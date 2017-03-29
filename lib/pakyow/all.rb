%w(
  support
  core
  presenter
  mailer
  realtime
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
