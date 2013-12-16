module Pakyow
  module Presenter
    class Page
      MATTER_MATCHER = /^(---\s*\n.*?\n?)^(---\s*$\n?)/m

      class << self
        def load(path)
          format   = Utils::String.split_at_last_dot(path)[-1]
          name     = File.basename(path, '.*').to_sym
          contents = FileTest.file?(path) ? File.read(path) : nil

          return Page.new(name, contents, path, format)
        end
      end

      attr_reader :contents, :path

      def initialize(name, contents, path, format = :html)
        @name, @contents, @path, @format = name, contents, path, format

        @info    = { template: :pakyow }
        @content = {}

        unless @contents.nil?
          parse_info
          parse_content
        end
      end

      def initialize_copy(original_page)
        super

        # copy content
        @content = {}
        original_page.content.each_pair do |k, v|
          @content[k] = v.dup
        end
      end

      def content(container = nil)
        return container.nil? ? @content : @content[container.to_sym]
      end

      def info(key = nil)
        return @info if key.nil?
        return @info[key]
      end

      def ==(page)
        @contents == page.contents
      end

      def to_view(container = :default)
        View.new(@content[container])
      end

      def to_html(container = :default)
        @content[container]
      end
      alias :to_s :to_html

      private

      def parse_info
        info = parse_front_matter(@contents)
        info = {} if !info || !info.is_a?(Hash)

        @info.merge!(Utils::Hash.symbolize(info))
      end

      def parse_content
        # remove yaml front matter
        @contents.gsub!(/---(.|\n)*---/, '')

        # process contents
        @contents = Presenter.process(@contents, @format)

        # find content in named containers
        within_regex = /<!--\s*@within\s*([a-zA-Z0-9\-_]*)\s*-->(.*?)<!--\s*\/within\s*-->/m

        @contents.scan(within_regex) do |m|
          container = m[0].to_sym
          @content[container] = m[1]
        end

        # find default content
        @content[:default] = @contents.gsub(within_regex, '')
      end

      def parse_front_matter(contents)
        matter = YAML.load(contents.match(MATTER_MATCHER).to_s)
        return matter
      end
    end
  end
end
