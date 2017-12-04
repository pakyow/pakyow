# frozen_string_literal: true

%w(
  support
  core
  presenter
).each do |lib|
  require "pakyow/#{lib}"
end
