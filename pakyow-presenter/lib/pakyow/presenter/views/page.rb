# frozen_string_literal: true

require "yaml"

module Pakyow
  module Presenter
    class Page
      class << self
        def load(path, content: nil, **args)
          Page.new(File.basename(path, ".*").to_sym, content || File.read(path), path, **args)
        end
      end

      attr_reader :path, :contents, :logical_path

      def initialize(name, html, path, **args)
        @name, @contents, @path = name, html, path

        @logical_path = args[:logical_path]

        @info = { template: :default }
        @containers = {}

        parse
      end

      def initialize_copy(_)
        super

        @containers = Hash[@containers.map { |key, value|
          [key, value.dup]
        }]
      end

      def content(container)
        container(container)&.object
      end

      # TODO: frontmatter should be supported in View
      def info(key = nil)
        return @info if key.nil?
        @info[key]
      end

      def ==(other)
        @contents == other.contents
      end

      def container(name)
        @containers[name.to_sym]
      end

      def each_container
        @containers.each_pair { |name, container| yield(name, container) }
      end

      private

      def parse
        parse_info
        parse_content
      end

      def parse_info
        @info.merge!(FrontMatterParser.parse(@contents, self.path))
      end

      def parse_content
        # remove yaml front matter
        @contents = FrontMatterParser.scrub(@contents)

        # process contents
        # @contents = Presenter.process(@contents, @format)

        # find content in named containers
        within_regex = /<!--\s*@within\s*([a-zA-Z0-9\-_]*)\s*-->(.*?)<!--\s*\/within\s*-->/m

        @contents.scan(within_regex) do |m|
          container_name = m[0].to_sym
          @containers[container_name] = Container.new(m[1])
        end

        # find default content
        @containers[:default] = Container.new(@contents.gsub(within_regex, ""))
      end
    end
  end
end
