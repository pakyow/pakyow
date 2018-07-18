# frozen_string_literal: true

require "http"

require "pakyow/support/cli/runner"

module Pakyow
  module Assets
    # @api private
    class External
      attr_reader :name, :version, :package

      def initialize(name, version:, package:, config:)
        @name, @version, @config = name, version, config
        @package = package || name
      end

      def exist?
        Dir.glob(File.join(@config.externals.asset_packs_path, "#{@name}*.js")).any?
      end

      def fetch!
        name_with_version = if @version
          "#{name}@#{@version}"
        else
          name.to_s
        end

        package_with_version = if @version
          "#{@package}@#{@version}"
        else
          @package.to_s
        end

        Support::CLI::Runner.new(message: "Fetching #{name_with_version}").run do |runner|
          begin
            response = HTTP.follow(true).get(
              File.join(
                @config.externals.provider,
                package_with_version
              )
            )

            if response.code == 200
              FileUtils.mkdir_p(@config.externals.asset_packs_path)

              fetched_version = response.uri.to_s.split(@package.to_s, 2)[1].split("/", 2)[0].split("@", 2)[1]

              local_path = File.join(
                @config.externals.asset_packs_path,
                "#{name}@#{fetched_version}.js"
              )

              File.open(local_path, "w") { |file|
                file.write(response.body.to_s)
              }

              runner.succeeded
            else
              runner.failed(response.to_s)
            end
          rescue HTTP::ConnectionError => error
            runner.failed(error.to_s)
          end
        end
      end
    end
  end
end
