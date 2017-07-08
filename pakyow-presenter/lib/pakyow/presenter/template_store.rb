require "pakyow/support/deep_dup"
require "pakyow/support/dir_walk"

module Pakyow
  module Presenter
    class TemplateStore
      using Support::DeepDup
      using Support::WalkDir

      attr_reader :name, :path

      def initialize(name, path)
        @name, @path = name, path

        load_templates
        load_path_info
      end

      # TODO: rename to: view_for_path?
      def at?(path)
        @path_info.key?(normalize_path(path))
      end

      # TODO: rename to: layout
      def template(name_or_path)
        if name_or_path.is_a?(Symbol)
          template_with_name(name_or_path)
        else
          at_path(name_or_path, :template)
        end
      end

      def page(view_path)
        at_path(view_path, :page)
      end

      def partials(view_path)
        at_path(view_path, :partials) || {}
      end

      def partial(view_path, name)
        partials(view_path)[name.to_sym]
      end

      # iterations through known views, yielding each
      def views
        @path_info.each_pair do |path, info|
          yield(info[:composer].view, path)
        end
      end

      def infos
        @path_info.each_pair do |path, info|
          yield(info, path)
        end
      end

      def expand_path(view_path)
        File.join(@path, view_path)
      end

      # Builds the full path to a partial.
      #
      #   expand_partial_path('path/to/partial')
      #   # => '{store_path}/path/to/_partial.html'
      def expand_partial_path(path)
        parts = path.split('/')

        # add underscore
        expanded_path = expand_path((parts[0..-2] << "_#{parts[-1]}").join('/'))

        # attempt to find extension
        matches = Dir.glob(expanded_path + '.*')

        if matches.empty?
          nil
        else
          expanded_path + File.extname(matches[0])
        end
      end

      def at_path(view_path)
        normalized_path = normalize_path(view_path)

        if info = @path_info[normalized_path]
          duped_info = info.dup
          duped_info.each_pair do |key, value|
            duped_info[key] = value.dup
          end
        else
          nil
        end
      end

      private

      def template_with_name(name)
        load_templates

        unless template = @templates[name.to_sym]
          raise MissingTemplate, "No template named '#{name}'"
        end

        return template
      end

      # really this is load_layouts
      def load_templates
        @templates = {}
        t_path = templates_path(@path)
        return unless File.exist?(t_path)

        Dir.entries(t_path).each do |file|
          next if file =~ /^\./

          template = Template.load(File.join(t_path, file))
          @templates[template.name] = template
        end
      end

      def templates_path(store_path)
        return File.join(store_path, "_templates")
      end

      def load_path_info
        @path_info = {}

        # for keeping up with pages for previous paths
        pages = {}

        Dir.walk(@path) do |path|
          # don't include templates
          next if path.include?(templates_path(@path))

          # skip partial files
          next if File.basename(path)[0,1] == '_'

          # skip non-empty folders (these files will be picked up)
          next unless Dir.glob(File.join(path, 'index.*')).empty?

          normalized_path = normalize_path(path)

          # if path is a directory we know there's no index page
          # so use the previous index page instead. this allows
          # partials to be overridden at a path while the same
          # page is used
          if File.directory?(path)
            # gets the path for the previous page
            prev_path = normalized_path
            until page = pages[prev_path]
              break if prev_path.empty?
              prev_path = prev_path.split('/')[0..-2].join("/")
            end
            page = page
          else
            page = Page.load(path)
            pages[normalized_path] = page
          end

          unless page.nil?
            template = template_with_name(page.info(:template))
          end

          #TODO more efficient way of doing this? lot of redundant calls here
          partials = partials_at_path(path)

          # unless page.nil?
          #   # compose template/page/partials
          #   composer = ViewComposer.from_path(self, normalized_path, template: template, page: page, includes: partials)
          # end

          info = {
            page: page,
            template: template,
            partials: partials,
            # composer: composer,
          }

          @path_info[normalized_path] = info
        end

        @path_info = Hash[@path_info.sort { |a, b| a <=> b }]
      end

      # TODO: might be some improvements to this with Pathname
      def normalize_path(path)
        # make it a relative path
        relative_path = path.gsub(@path, '')
        # remove the extension
        relative_path = relative_path.gsub(File.extname(relative_path), '')
        # remove index from the end
        relative_path = relative_path.gsub('index', '')
        # actually normalize it
        relative_path = String.normalize_path(relative_path)
        relative_path
      end

      def partials_at_path(view_path)
        view_path = File.dirname(view_path) unless File.directory?(view_path)
        view_path = normalize_path(view_path)

        partials = {}
        Dir.walk(@path) do |path|
          # skip non-partials
          next unless File.basename(path)[0,1] == '_'

          # skip directories
          next if File.directory?(path)

          # skip files not within `view_path`
          next unless Dir.within_dir?(normalize_path(File.dirname(path)), view_path)

          name = File.basename(path.split('/')[-1], '.*')[1..-1]
          partials[name.to_sym] = path
        end

        # create instances
        partials.each do |name, path|
          partials[name] = Partial.load(path)
        end

        return partials
      end
    end
  end
end
