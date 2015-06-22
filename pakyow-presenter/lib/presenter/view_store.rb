module Pakyow
  module Presenter
    class ViewStore
      attr_reader :store_name, :store_paths, :templates

      def initialize(store_path_or_paths, store_name = :default)
        @store_name = store_name
        @store_paths = Array.ensure(store_path_or_paths)

        load_templates
        load_path_info
      end

      def at?(view_path)
        begin
          at_path(view_path)
          return true
        rescue MissingView
          return false
        end
      end

      def template(name_or_path)
        return name_or_path if name_or_path.is_a?(Template)

        if name_or_path.is_a?(Symbol)
          return template_with_name(name_or_path)
        else
          return at_path(name_or_path, :template)
        end
      end

      def page(view_path)
        return view_path if view_path.is_a?(Page)

        raise ArgumentError, "Cannot build page for nil path" if view_path.nil?
        return at_path(view_path, :page)
      end

      def partials(view_path)
        return at_path(view_path, :partials) || {}
      end

      def partial(view_path, name)
        return partials(view_path)[name.to_sym]
      end

      def composer(view_path)
        return at_path(view_path, :composer)
      end

      def view(view_path)
        return composer(view_path).view
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
        @store_paths.each do |store_path|
          path = File.join(store_path, view_path)

          if File.extname(path).empty?
            return path if !Dir.glob(path + '.*').empty?
          else
            return path if File.exist?(path)
          end
        end

        nil
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
        raise MissingPartial, "Could not find partial with any extension at #{expanded_path}" if matches.empty?

        return expanded_path + File.extname(matches[0])
      end

      private

      def at_path(view_path, obj = nil)
        normalized_path = normalize_path(view_path)
        info = @path_info[normalized_path]

        if info.nil?
          raise MissingView, "No view at path '#{view_path}'"
        else
          #TODO need to consider whose responsibility it is to make the dups
          return (obj ? info[obj.to_sym] : info).dup
        end
      end

      def template_with_name(name)
        load_templates

        unless template = @templates[name.to_sym]
          raise MissingTemplate, "No template named '#{name}'"
        end

        return template.dup
      end

      def load_templates
        return if templates_loaded?

        @templates = {}
        @store_paths.each do |store_path|
          t_path = templates_path(store_path)
          next unless File.exists?(t_path)

          Dir.entries(t_path).each do |file|
            next if file =~ /^\./

            template = Template.load(File.join(t_path, file))
            @templates[template.name] = template
          end
        end

        raise MissingTemplatesDir, 'No templates found' if @templates.empty?
        @templates_loaded = true
      end

      def templates_loaded?
        @templates_loaded == true
      end

      def templates_path(store_path)
        return File.join(store_path, Config.presenter.template_dir(@store_name))
      end

      def load_path_info
        @path_info = {}

        # for keeping up with pages for previous paths
        pages = {}

        @store_paths.each do |store_path|
          Dir.walk(store_path) do |path|
            # skip root
            next if path == store_path

            # don't include templates
            next if path.include?(templates_path(store_path))

            # skip partial files
            next if File.basename(path)[0,1] == '_'

            # skip non-empty folders (these files will be picked up)
            next if !Dir.glob(File.join(path, 'index.*')).empty?

            normalized_path = normalize_path(path, store_path)

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

            next if page.nil?
            template = template_with_name(page.info(:template))

            #TODO more efficient way of doing this? lot of redundant calls here
            partials = partials_at_path(path)

            # compose template/page/partials
            composer = ViewComposer.from_path(self, normalized_path, template: template, page: page, includes: partials)

            info = {
              page: page,
              template: template,
              partials: partials,
              composer: composer,
            }

            @path_info[normalized_path] = info
          end
        end
      end

      def normalize_path(path, store_path = nil)
        if store_path
          relative_path = path.gsub(store_path, '')
        else
          relative_path = path
          @store_paths.each do |store_path|
            relative_path = relative_path.gsub(store_path, '')
          end
        end

        relative_path = relative_path.gsub(File.extname(relative_path), '')
        relative_path = relative_path.gsub('index', '')
        relative_path = String.normalize_path(relative_path)

        return relative_path
      end

      def partials_at_path(view_path)
        view_path = File.dirname(view_path) unless File.directory?(view_path)
        view_path = normalize_path(view_path)

        partials = {}
        @store_paths.each do |store_path|
          Dir.walk(store_path) do |path|
            # skip non-partials
            next unless File.basename(path)[0,1] == '_'

            # skip directories
            next if File.directory?(path)

            # skip files not within `view_path`
            next unless Dir.within_dir?(normalize_path(File.dirname(path), store_path), view_path)

            name = File.basename(path.split('/')[-1], '.*')[1..-1]
            partials[name.to_sym] = path
          end
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
