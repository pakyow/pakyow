# frozen_string_literal: true

require "http"

require "pakyow/support/cli/runner"

module Pakyow
  module Assets
    # @api private
    class External
      attr_reader :name, :version, :package

      def initialize(name, version:, package:, files:, config:)
        @name, @version, @config = name, version, config
        @package = package || name
        @files = files || []
      end

      def exist?
        if @files.empty?
          Dir.glob(File.join(@config.externals.path, "#{@name}*.js")).any?
        else
          !@files.any? { |file|
            if File.basename(file, File.extname(file)) == @name.to_s
              Dir.glob(File.join(@config.externals.path, "#{@name}*.js")).empty?
            else
              Dir.glob(File.join(@config.externals.path, "#{@name}*__#{File.basename(file, File.extname(file))}.js")).empty?
            end
          }
        end
      end

      def fetch!
        if @files.empty?
          fetch_file!(nil)
        else
          @files.each do |file|
            fetch_file!(file)
          end
        end
      end

      private

      def fetch_file!(file)
        name_with_version = if @version
          "#{name}@#{@version}"
        else
          name.to_s
        end

        file_with_version = File.join(name_with_version, file.to_s).chomp("/")

        package_with_version = if @version
          "#{@package}@#{@version}"
        else
          @package.to_s
        end

        Support::CLI::Runner.new(message: "Fetching #{file_with_version}").run do |runner|
          begin
            response = HTTP.follow(true).get(
              File.join(
                @config.externals.provider,
                package_with_version,
                file.to_s
              )
            )

            if response.code == 200
              FileUtils.mkdir_p(@config.externals.path)

              fetched_version = response.uri.to_s.split(@package.to_s, 2)[1].split("/", 2)[0].split("@", 2)[1]
              file_basename = File.basename(file.to_s, File.extname(file.to_s))

              local_path = if file && file_basename != name.to_s
                File.join(
                  @config.externals.path,
                  "#{name}@#{fetched_version}__#{file_basename}.js"
                )
              else
                File.join(
                  @config.externals.path,
                  "#{name}@#{fetched_version}.js"
                )
              end

              File.open(local_path, "w") do |fp|
                fp.write(response.body.to_s)
              end

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
