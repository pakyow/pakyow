# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/core_refinements/string/normalization"

require_relative "front_matter_parser"
require_relative "views/layout"
require_relative "views/page"
require_relative "views/partial"

module Pakyow
  module Presenter
    class Templates
      using Support::DeepDup
      using Support::Refinements::String::Normalization

      attr_reader :name, :path, :processor, :layouts, :pages, :includes, :config

      DEFAULT_LAYOUTS_PATH = "layouts"
      DEFAULT_PARTIALS_PATH = "includes"
      DEFAULT_PAGES_PATH = "pages"

      def initialize(name, path, processor: nil, config: {})
        @name, @path, @processor = name, Pathname(path), processor
        @layouts, @includes, @info = {}, {}, {}
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
          @info[path]
        end
      end

      def layout(name_or_path)
        if name_or_path.is_a?(Symbol)
          layout_with_name(name_or_path)
        else
          info(name_or_path) & [:layout]
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

      # Yields each template.
      #
      def each
        @info.each do |_path, info|
          yield info[:layout]
          yield info[:page]
          info[:partials].each do |_name, partial|
            yield partial
          end
        end
      end

      private

      def build_config(config)
        @config = {
          prefix: config[:prefix] || "/",
          paths: {
            layouts: config.dig(:paths, :layouts) || DEFAULT_LAYOUTS_PATH,
            pages: config.dig(:paths, :pages) || DEFAULT_PAGES_PATH,
            partials: config.dig(:paths, :partials) || DEFAULT_PARTIALS_PATH,
          }
        }
      end

      def layout_with_name(name)
        @layouts[name.to_sym]
      end

      def load_templates
        load_layouts
        load_partials
        load_path_info
      end

      def load_layouts
        return unless layouts_path.exist?

        layouts_path.children.each_with_object(@layouts) { |file, layouts|
          next unless template?(file)

          if layout = load_view_of_type_at_path(Views::Layout, file)
            layouts[layout.name] = layout
          end
        }
      end

      def load_partials
        return unless partials_path.exist?

        partials_path.children.each_with_object(@includes) { |file, partials|
          next unless template?(file)

          if partial = load_view_of_type_at_path(Views::Partial, file, normalize_path(file))
            partials[partial.name] = partial
          end
        }
      end

      def load_path_info
        pages_path.glob("**/*").select { |path|
          template?(path)
        }.reject { |path|
          path.basename.to_s.start_with?("_")
        }.each do |path|
          if page = page_at_path(path)
            path_to_page = String.normalize_path(
              File.join(
                @config[:prefix], normalize_path(path, pages_path)
              )
            )

            @info[path_to_page] = {
              page: page,

              layout: layout_with_name(
                page.info(:layout)
              ),

              partials: @includes.merge(
                partials_at_path(path)
              )
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

      def page_at_path(path)
        if File.directory?(path)
          if Dir.glob(File.join(path, "index.*")).empty?
            index_page_at_path(path)
          end
        else
          load_view_of_type_at_path(Views::Page, path, normalize_path(path))
        end
      end

      def index_page_at_path(path)
        ascend(path) do |parent_path|
          next unless info = info(normalize_path(parent_path))
          next unless page = info[:page]
          return page
        end
      end

      def partials_at_path(path)
        ascend(path).select(&:directory?).each_with_object({}) { |parent_path, partials|
          parent_path.children.select { |child|
            child.basename.to_s.start_with?("_")
          }.each_with_object(partials) { |child, child_partials|
            if partial = load_view_of_type_at_path(Views::Partial, child, normalize_path(child))
              child_partials[partial.name] ||= partial
            end
          }
        }
      end

      def load_view_of_type_at_path(type, path, logical_path = nil)
        extension = File.extname(path)

        if extension.end_with?(".html") || @processor&.process?(extension)
          content = File.read(path)
          info, content = FrontMatterParser.parse_and_scrub(content)

          if @processor
            content = @processor.process(content, extension.delete(".").to_sym)
          end

          type.load(path, info: info, content: content, logical_path: logical_path)
        else
          nil
        end
      end

      def ascend(path)
        return enum_for(:ascend, path) unless block_given?

        path.ascend.each do |path|
          yield path

          if path == @path
            break
          end
        end
      end

      def normalize_path(path, relative_from = @path)
        # make it relative
        path = path.expand_path.relative_path_from(relative_from.expand_path)

        # we can short-circuit here
        return "/" if path.to_s == "."

        # remove the extension
        path = path.sub_ext("")

        # remove index from the end
        path = path.sub("index", "")

        # actually normalize it
        String.normalize_path(path.to_s)
      end
    end
  end
end
