# frozen_string_literal: true

%w(
  support
  core
  data
  presenter
  realtime
).each do |lib|
  require "pakyow/#{lib}"
end
