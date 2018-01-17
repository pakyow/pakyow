# frozen_string_literal: true

namespace :assets do
  task :json, [:app] do |_, args|
    puts args[:app].config.assets.to_hash.to_json
  end
end
