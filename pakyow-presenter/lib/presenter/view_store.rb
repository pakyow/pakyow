module Pakyow
  class ViewStore
    attr_reader :name, :store_path, :templates

    def initialize(store_path, name = :default)
      @name = name
      @store_path = store_path

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
      if name_or_path.is_a?(Symbol)
        return template_with_name(name_or_path)
      else
        return at_path(name_or_path, :template)
      end
    end

    def page(view_path)
      return at_path(view_path, :page).dup
    end

    def view(view_path)
      return at_path(view_path, :view).dup
    end

    def partial(view_path, name)
      return at_path(view_path, :partials)[name.to_sym]
    end

    # iterations through known views, yielding each
    def views
      @path_info.each_pair do |path, info|
        yield(info[:view], path)
      end
    end

    def infos
      @path_info.each_pair do |path, info|
        yield(info, path)
      end
    end

    private

    def at_path(view_path, obj = nil)
      normalized_path = normalize_path(view_path)
      info = @path_info[normalized_path]

      if info.nil?
        raise MissingView, "No view at path '#{view_path}'"
      else
        return obj ? info[obj.to_sym] : info
      end
    end

    def template_with_name(name)
      unless template = @templates[name.to_sym]
        raise MissingTemplate, "No template named '#{name}'"
      end

      return template
    end

    def load_templates
      @templates = {}

      if File.exists?(templates_path)
        Dir.entries(templates_path).each do |file|
          next if file == '.' || file == '..'

          template = Template.load(File.join(templates_path, file))
          @templates[template.name] = template
        end
      else
        raise MissingTemplatesDir, "No templates found at '#{templates_path}'"
      end
    end

    def templates_path
      return File.join(@store_path, Config::Base.presenter.template_dir(@name))
    end

    def load_path_info
      @path_info = {}

      # for keeping up with pages for previous paths
      pages = {}

      Utils::Dir.walk_dir(@store_path) do |path|
        # skip root
        next if path == @store_path

        # don't include templates
        next if path.include?(templates_path)

        # skip partial files
        next if File.basename(path)[0,1] == '_'

        # skip non-empty folders (these files will be picked up)
        next if !Dir.glob(File.join(path, 'index.*')).empty?

        normalized_path = normalize_path(path)

        # if path is a directory we know there's no index page
        # so use the previous index page instead. this allows
        # partials to be overridden at a path while the same
        # page is used
        if File.directory?(path)
          # gets the path for the previous page
          prev_path = normalized_path
          until page = pages[prev_path]
            prev_path = prev_path.split('/')[0..-2].join("/")
          end
          page = page.dup
        else
          page = Page.load(path)
          pages[normalized_path] = page.dup
        end

        template = template_with_name(page.info(:template)).dup

        #TODO more efficient way of doing this? lot
        # of redundant calls here
        partials = partials_at_path(path)

        # compose page/partials
        page.include_partials(partials)

        # compose template/partials
        template.include_partials(partials)

        # compose template/page
        view = template.build(page)

        # build partials
        #view.build(partials)

        # set title
        title = page.info(:title)
        view.title = title unless title.nil?

        info = {
          view: view,
          page: page,
          template: template,
          partials: partials,
        }

        @path_info[normalized_path] = info
      end
    end

    def normalize_path(path)
      relative_path = path.gsub(@store_path, '')
      relative_path = relative_path.gsub(File.extname(relative_path), '')
      relative_path = relative_path.gsub('index', '')
      relative_path = Utils::String.normalize_path(relative_path)

      return relative_path
    end

    def partials_at_path(view_path)
      view_path = File.dirname(view_path) unless File.directory?(view_path)

      partials = {}
      Utils::Dir.walk_dir(@store_path) do |path|
        # skip non-partials
        next unless File.basename(path)[0,1] == '_'

        # skip directories
        next if File.directory?(path)

        # skip files not within `view_path`
        next unless Utils::Dir.dir_within_dir?(File.dirname(path), view_path)

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
