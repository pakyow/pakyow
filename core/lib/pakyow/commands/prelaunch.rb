# frozen_string_literal: true

command :prelaunch do
  describe "Run all phases of the prelaunch sequence"
  required :cli

  action do
    %w[prelaunch:build prelaunch:release].each do |command|
      @cli.call(command)
    end
  end
end
