module Pakyow
  module Presenter
    class Page
      MATTER_MATCHER = /^(---\s*\n.*?\n?)^(---\s*$\n?)/m

      class << self
        def load(path)
          format   = StringUtils.split_at_last_dot(path)[-1]
          name     = File.basename(path, '.*').to_sym
          contents = FileTest.file?(path) ? File.read(path) : nil

          return Page.new(name, contents, format)
        end
      end

      attr_reader :contents

      def initialize(name, contents, format = :html)
        @name = name
        @contents = contents
        @format = format

        @info    = {}
        @content = {}

        unless @contents.nil?
          parse_info
          parse_content
        end

        partials
      end

      def initialize_copy(original_page)
        super

        # copy content
        @content = {}
        original_page.content.each_pair do |k, v|
          @content[k] = v.dup
        end
      end

      def build(partial_map)
        partials.each do |container, partial_list|
          partial_list.each do |partial_name|
            regex = /<!--\s*@include\s*#{partial_name}\s*-->/
            @content[container].gsub!(regex, partial_map[partial_name].to_s)

            partial_map.delete(partial_name)
          end
        end

        # we have more partials
        if partial_map.count > 0
          # initiate another build if content contains partials
          build(partial_map) if partials(true).count > 0
        end

        return self
      end

      def content(container = nil)
        return container.nil? ? @content : @content[container.to_sym]
      end

      def template
        @info[:template] || :pakyow
      end

      def ==(page)
        @contents == page.contents
      end

      def partials(refind = false)
        @partials = (!@partials || refind) ? find_partials : @partials
      end

      private

      def parse_info
        info = parse_front_matter(@contents)
        info = {} if !info || !info.is_a?(Hash)

        @info = HashUtils.symbolize(info)
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

      # returns an array of hashes, each with the partial name and doc
      def find_partials
        partials = {}

        partial_regex = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/
        @content.each do |name, content|
          content.scan(partial_regex) do |m|
            partials[name] ||= []
            partials[name] << m[0].to_sym
          end
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
