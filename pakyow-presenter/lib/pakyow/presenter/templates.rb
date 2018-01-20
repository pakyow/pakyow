# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Presenter
    class Templates
      using Support::DeepDup

      attr_reader :name, :path, :layouts, :pages

      DEFAULT_LAYOUTS_PATH = "layouts"
      DEFAULT_PARTIALS_PATH = "includes"
      DEFAULT_PAGES_PATH = "pages"

      def initialize(name, path, processor: nil, config: {})
        @name, @path, @processor = name, Pathname(path), processor
        build_config(config)
        load_templates
      end

      def view?(path)
        @info.key?(path)
      end

      def paths
        @info.keys
      end

      def info(path)
        if view?(path)
          @info[path].deep_dup
        end
      end

      def layout(name_or_path)
        if name_or_path.is_a?(Symbol)
          layout_with_name(name_or_path)
        else
          info(name_or_path) & [:template]
        end
      end

      def page(path)
        info(path) & [:page]
      end

      def partials(path)
        info(path) & [:partials] || {}
      end

      def partial(path, name)
        partials(path)[name.to_sym]
      end

      def layouts_path
        path.join(@config[:paths][:layouts])
      end

      def partials_path
        path.join(@config[:paths][:partials])
      end

      def pages_path
        path.join(@config[:paths][:pages])
      end

      def template?(path)
        return false if path.basename.to_s.start_with?(".")
        return false unless path.extname == ".html" || @processor&.process?(path.extname)

        true
      end

      private

      def layout_with_name(name)
        load_layouts

        unless layout = @layouts[name.to_sym]
          raise MissingLayout, "No layout named '#{name}'"
        end

        layout
      end

      def build_config(config)
        @config = {
          paths: {
            layouts: config.dig(:paths, :layouts) || DEFAULT_LAYOUTS_PATH,
            pages: config.dig(:paths, :pages) || DEFAULT_PAGES_PATH,
            partials: config.dig(:paths, :partials) || DEFAULT_PARTIALS_PATH,
          }
        }
      end

      def load_templates
        load_layouts
        load_partials
        load_path_info
      end

      def load_layouts
        @layouts = {}
        return unless File.exist?(layouts_path)

        @layouts = layouts_path.children.each_with_object({}) { |file, layouts|
          next unless template?(file)
          layout = load_view_of_type_at_path(Layout, file)
          layouts[layout.name] = layout
        }
      end

      def load_partials
        @partials = {}
        return unless File.exist?(partials_path)

        @partials = partials_path.children.each_with_object({}) { |file, partials|
          next unless template?(file)
          partial = load_view_of_type_at_path(Partial, file, normalize_path(file))
          partials[partial.name] = partial
        }
      end

      def load_path_info
        @info = {}

        Pathname.glob(File.join(pages_path, "**/*")) do |path|
          # TODO: better way to skip partials?
          next if path.basename.to_s.start_with?("_")

          next unless template?(path)

          begin
            if page = page_at_path(path)
              @info[normalize_path(path, pages_path)] = {
                page: page,
                template: layout_with_name(page.info(:layout)),
                partials: @partials.merge(partials_at_path(path))
              }
            end
          rescue FrontMatterParsingError => e
            message = "Could not parse front matter for #{path}:\n\n#{e.context}"

            if e.wrapped_exception
              message << "\n#{e.wrapped_exception.problem} at line #{e.wrapped_exception.line} column #{e.wrapped_exception.column}"
            end

            raise FrontMatterParsingError.new(message)
          end
        end
      end

      def page_at_path(path)
        if File.directory?(path)
          if Dir.glob(File.join(path, "index.*")).empty?
            index_page_at_path(path)
          end
        else
          load_view_of_type_at_path(Page, path, normalize_path(path))
        end
      end

      def index_page_at_path(path)
        # TODO: don't ascend above store path
        path.ascend do |parent_path|
          next unless info = info(normalize_path(parent_path))
          next unless page = info[:page]
          return page
        end
      end

      # TODO: do we always need to make it relative, etc here?
      # maybe break up these responsibilities to the bare minimum required
      def normalize_path(path, relative_from = @path)
        path = path.expand_path
        relative_from = relative_from.expand_path

        # make it relative
        path = path.relative_path_from(relative_from)
        # we can short-circuit here
        return "/" if path.to_s == "."

        # remove the extension
        path = path.sub_ext("")

        # remove index from the end
        path = path.sub("index", "")

        # actually normalize it
        String.normalize_path(path.to_s)
      end

      def partials_at_path(path)
        # FIXME: don't ascend above store path
        path.ascend.select(&:directory?).each_with_object({}) { |parent_path, partials|
          parent_path.children.select { |child|
            child.basename.to_s.start_with?("_")
          }.each_with_object(partials) { |child, child_partials|
            partial = load_view_of_type_at_path(Partial, child, normalize_path(child))
            child_partials[partial.name] ||= partial
          }
        }
      end

      def load_view_of_type_at_path(type, path, logical_path = nil)
        content = File.read(path)
        info, content = FrontMatterParser.parse_and_scrub(content)

        if @processor
          extension = File.extname(path).delete(".").to_sym
          type.load(path, info: info, content: @processor.process(content, extension), logical_path: logical_path)
        else
          type.load(path, info: info, logical_path: logical_path)
        end
      end
    end
  end
end
