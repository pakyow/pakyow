# frozen_string_literal: true

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
          Async do
            downloader = Downloader.new(
              File.join(@config.externals.provider, CGI.escape(package_with_version), CGI.escape(file.to_s))
            ).perform

            FileUtils.mkdir_p(@config.externals.path)

            fetched_version = CGI.unescape(downloader.path.to_s).split(@package.to_s, 2)[1].split("/", 2)[0].split("@", 2)[1]
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
              fp.write(downloader.body.to_s)
            end

            runner.succeeded
          rescue Downloader::Failed => error
            runner.failed(error.to_s)
          end
        end
      end

      require "uri"

      require "async"
      require "async/http/internet"

      # @api private
      class Downloader
        attr_reader :status, :body, :path

        def initialize(uri)
          @uri = URI.parse(uri)
        end

        def perform
          get(@uri.path); self
        end

        private def get(path)
          @path = path
          internet = Async::HTTP::Internet.new
          response = internet.get(build_uri(path))
          @status = response.status

          if response.status == 301 || response.status == 302
            get(response.headers["location"])
          elsif response.status >= 500
            raise Failed, "Unexpected response status: #{response.status}"
          else
            @body = response.body.read
          end
        rescue SocketError => error
          raise Failed.build(error)
        ensure
          response&.close
          internet&.close
        end

        private def build_uri(path)
          File.join("#{@uri.scheme}://#{@uri.host}", path)
        end

        class Failed < Error; end
      end
    end
  end
end
