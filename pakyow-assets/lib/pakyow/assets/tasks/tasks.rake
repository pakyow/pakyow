# frozen_string_literal: true

namespace :assets do
  desc "Precompiles assets"
  task :precompile, [:app] do |_, args|
    exec "PAKYOW_ASSETS_CONFIG='#{Base64.encode64(args[:app].config.assets.to_hash.to_json)}' #{args[:app].config.assets.webpack_command}"
  end
end
