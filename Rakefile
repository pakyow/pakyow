# frozen_string_literal: true

GEMS = if ENV.key?("GEMS")
  ENV["GEMS"].split(",").map(&:to_sym).freeze
else
  %i(
    assets
    core
    data
    form
    mailer
    presenter
    realtime
    routing
    support
    ui
  ).freeze
end

Dir.glob("tasks/*.rake").each do |r| import r end
task default: %w(test:all)
