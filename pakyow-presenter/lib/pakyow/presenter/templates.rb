# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/core_refinements/string/normalization"

require_relative "front_matter_parser"
require_relative "views/layout"
require_relative "views/page"
require_relative "views/partial"

module Pakyow
  module Presenter
    class Templates
      using Support::DeepDup
      using Support::Refinements::Array::Ensurable
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

      def layout_paths
        @config[:paths][:layouts]
      end

      def partial_paths
        @config[:paths][:partials]
      end

      def page_paths
        @config[:paths][:pages]
      end

      def template?(path)
        return false if path.basename.to_s.start_with?(".")
        return false unless path.extname == ".html" || @processor&.process?(path.extname)

        true
      end

      # Yields each template.
      #
      def each
        @info.each_value do |info|
          yield info[:layout]
          yield info[:page]

          info[:partials].each_value do |partial|
            yield partial
          end
        end
      end

      private def build_config(config)
        @config = {
          prefix: config[:prefix] || "/",
          paths: {
            layouts: Array.ensure(config.dig(:paths, :layouts) || DEFAULT_LAYOUTS_PATH).map { |layout_path|
              build_path(layout_path)
            }.select(&:exist?),
            pages: Array.ensure(config.dig(:paths, :pages) || DEFAULT_PAGES_PATH).map { |page_path|
              build_path(page_path)
            }.select(&:exist?),
            partials: Array.ensure(config.dig(:paths, :partials) || DEFAULT_PARTIALS_PATH).map { |partial_path|
              build_path(partial_path)
            }.select(&:exist?)
          }
        }
      end

      private def build_path(path)
        case path
        when Pathname
          path
        else
          @path.join(path)
        end
      end

      private def layout_with_name(name)
        @layouts[name.to_sym]
      end

      private def load_templates
        load_layouts
        load_partials
        load_path_info
      end

      private def load_layouts
        return unless layout_paths.any?

        layout_paths.each do |layouts_path|
          layouts_path.children.each do |file|
            next unless template?(file)

            if (layout = load_view_of_type_at_path(Views::Layout, file))
              @layouts[layout.name] ||= layout
            end
          end
        end
      end

      private def load_partials
        return unless partial_paths.any?

        partial_paths.each do |partials_path|
          partials_path.children.each do |file, partials|
            next unless template?(file)

            if (partial = load_view_of_type_at_path(Views::Partial, file, normalize_path(file)))
              @includes[partial.name] ||= partial
            end
          end
        end
      end

      private def load_path_info
        page_paths.each do |pages_path|
          pages_path.glob("**/*").select { |path|
            template?(path)
          }.reject { |path|
            path.basename.to_s.start_with?("_")
          }.each do |path|
            if (page = page_at_path(path))
              path_to_page = String.normalize_path(
                File.join(
                  @config[:prefix], normalize_path(path, pages_path)
                )
              )

              @info[path_to_page] ||= {
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
      end

      private def page_at_path(path)
        if File.directory?(path)
          if Dir.glob(File.join(path, "index.*")).empty?
            index_page_at_path(path)
          end
        else
          load_view_of_type_at_path(Views::Page, path, normalize_path(path))
        end
      end

      private def index_page_at_path(path)
        ascend(path) do |parent_path|
          next unless (info = info(normalize_path(parent_path)))
          next unless (page = info[:page])
          return page
        end
      end

      private def partials_at_path(path)
        ascend(path).select(&:directory?).each_with_object({}) { |parent_path, partials|
          parent_path.children.select { |child|
            child.basename.to_s.start_with?("_")
          }.each_with_object(partials) { |child, child_partials|
            if (partial = load_view_of_type_at_path(Views::Partial, child, normalize_path(child)))
              child_partials[partial.name] ||= partial
            end
          }
        }
      end

      private def load_view_of_type_at_path(type, path, logical_path = nil)
        extension = File.extname(path)

        if extension.end_with?(".html") || @processor&.process?(extension)
          content = File.read(path)
          info, content = FrontMatterParser.parse_and_scrub(content)

          if @processor
            content = @processor.process(content, extension.delete(".").to_sym)
          end

          type.load(path, info: info, content: content, logical_path: logical_path)
        end
      end

      private def ascend(path)
        return enum_for(:ascend, path) unless block_given?

        path.ascend.each do |each_path|
          yield each_path

          if each_path == @path
            break
          end
        end
      end

      private def normalize_path(path, relative_from = @path)
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
