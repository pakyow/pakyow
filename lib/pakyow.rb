DEPENDENCIES = %w[
  pakyow-support
  pakyow-core
  pakyow-presenter
  pakyow-mailer
]

DEPENDENCIES.each do |lib|
  require lib
end
