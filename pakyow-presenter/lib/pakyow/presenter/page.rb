module Pakyow
  module Presenter
    class Page
      MATTER_MATCHER = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m

      class << self
        def load(path, view_store_name = :default)
          format   = String.split_at_last_dot(path)[-1]
          name     = File.basename(path, '.*').to_sym
          contents = FileTest.file?(path) ? File.read(path) : nil

          return Page.new(name, contents, path, format, view_store_name)
        end
      end

      attr_reader :path, :contents

      def initialize(name, contents, path, format = :html, view_store_name = :default)
        @name, @contents, @path, @format = name, contents, path, format

        @info    = { template: Pakyow::App.config.presenter.default_view(view_store_name) }
        @containers = {}

        unless @contents.nil?
          parse_info
          parse_content
        end
      end

      def initialize_copy(original_page)
        super

        # copy content
        @containers = {}
        original_page.instance_variable_get(:'@containers').each_pair do |k, v|
          @containers[k] = v.dup
        end
      end

      def content(container = nil)
        return @contents if container.nil?

        container = @containers.fetch(container.to_sym) {
          raise MissingContainer, "No container named #{container} in #{@path}"
        }

        return container.doc
      end

      def info(key = nil)
        return @info if key.nil?
        return @info[key]
      end

      def ==(page)
        @contents == page.contents
      end

      def container(name)
        @containers.fetch(name.to_sym) {
          raise MissingContainer, "No container named #{name} in #{@path}"
        }
      end

      def each_container
        @containers.each_pair { |name, container| yield(name, container) }
      end

      private

      def parse_info
        info = parse_front_matter(@contents)
        info = {} if !info || !info.is_a?(Hash)

        @info.merge!(Hash.symbolize(info))
      end

      def parse_content
        # remove yaml front matter
        @contents.gsub!(/---(.|\n)*---/, '')

        # process contents
        @contents = Presenter.process(@contents, @format)

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
