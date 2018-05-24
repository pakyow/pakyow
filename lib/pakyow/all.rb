# frozen_string_literal: true

%w(
  assets
  core
  data
  mailer
  presenter
  realtime
  support
  ui
).each do |lib|
  require "pakyow/#{lib}"
end
