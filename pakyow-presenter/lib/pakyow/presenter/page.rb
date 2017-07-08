module Pakyow
  module Presenter
    # TODO: this should be refactored to PagePresenter
    # the front matter parsing should be part of view and exposed as `info` so that it works everywhere
    class Page
      MATTER_MATCHER = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m

      class << self
        def load(path)
          name = File.basename(path, '.*').to_sym
          html = FileTest.file?(path) ? File.read(path) : nil
          Page.new(name, html, path)
        end
      end

      attr_reader :path, :contents

      def initialize(name, html, path)
        @name, @contents, @path = name, html, path

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
        container(container).doc
      end

      # TODO: frontmatter should be supported in View
      def info(key = nil)
        return @info if key.nil?
        return @info[key]
      end

      def ==(page)
        @contents == page.contents
      end

      def container(name)
        @containers.fetch(name.to_sym) {
          # TODO: how do we really want to handle this?
          raise MissingContainer, "No container named #{name} in #{@path}"
        }
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
        info = parse_front_matter(@contents)
        info = {} if !info || !info.is_a?(Hash)

        @info.merge!(Hash.symbolize(info))
      end

      def parse_content
        # remove yaml front matter
        @contents.gsub!(/---(.|\n)*---/, '')

        # process contents
        # @contents = Presenter.process(@contents, @format)

        # find content in named containers
        within_regex = /<!--\s*@within\s*([a-zA-Z0-9\-_]*)\s*-->(.*?)<!--\s*\/within\s*-->/m

        @contents.scan(within_regex) do |m|
          container_name = m[0].to_sym
          @containers[container_name] = Container.new(m[1])
        end

        # find default content
        @containers[:default] = Container.new(@contents.gsub(within_regex, ''))
      end

      def parse_front_matter(contents)
        # match the matter
        matter = contents.match(MATTER_MATCHER).to_s

        # remove the opening/closing '---'
        matter = matter.split("\n")[1..-2]
        # return if no matter
        return {} if matter.nil?

        YAML.load(matter.join("\n"))
      end
    end
  end
end
