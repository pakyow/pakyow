# frozen_string_literal: true

GEMS = if ENV.key?("GEMS")
  ENV["GEMS"].split(",").map(&:to_sym).freeze
else
  %i[
    assets
    core
    data
    form
    mailer
    presenter
    realtime
    reflection
    routing
    support
    ui
  ].freeze
end

Dir.glob("tasks/*.rake").each { |r| import r }
task default: %w[test:all]
