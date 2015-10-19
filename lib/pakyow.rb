require 'version'

%w[
  pakyow-support
  pakyow-core
  pakyow-presenter
  pakyow-mailer
  pakyow-realtime
  pakyow-ui
].each do |lib|
  require lib
end
