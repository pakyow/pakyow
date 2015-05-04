DEPENDENCIES = %w[
  pakyow-support
  pakyow-core
  pakyow-presenter
  pakyow-mailer
  pakyow-realtime
]

DEPENDENCIES.each do |lib|
  require lib
end
