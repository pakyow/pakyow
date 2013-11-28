module Pakyow
  module Presenter
    class Page
      include PartialHelpers

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

      def include_partials(partial_map)
        partials.each do |container, partial_list|
          partial_list.each do |partial_name|
            @content[container].gsub!(PARTIAL_REGEX, partial_map[partial_name].to_s)
            partial_map.delete(partial_name)
          end

          # we have more partials
          if partial_map.count > 0
            # initiate another build if content contains partials
            include_partials(partial_map) if partials(true)[container].count > 0
          end
        end

        return self
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

      def find_partials
        partials = {}

        @content.each do |name, content|
          partials[name] = partials_in(content)
        end

        return partials
      end

      def parse_front_matter(contents)
        matter = YAML.load(contents.match(MATTER_MATCHER).to_s)
        return matter
      end
    end
  end
end
