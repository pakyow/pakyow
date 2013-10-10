module Pakyow
  module Config
    class Presenter
      Config::Base.register_config(:presenter, self)

      class << self
        attr_accessor :javascripts, :stylesheets, :view_stores, :default_views,
        :scope_attribute, :prop_attribute, :container_attribute, :template_dirs

        # Location of javascripts
        def javascripts
          @javascripts || '/javascripts'
        end

        # Location of stylesheets
        def stylesheets
          @stylesheets || '/stylesheets'
        end

        def view_stores
          @view_stores ||= {:default => "#{Config::Base.app.root}/app/views"}
        end

        def default_views(store_name = nil)
          @default_views ||= {:default => "pakyow.html"}
        end

        # Returns the default view for store, or default.
        #
        def default_view(store_name)
          views = default_views
          views.key?(store_name) ? views[store_name] : views[:default]
        end

        def template_dirs(store_name = nil)
          @template_dirs ||= {:default => '_templates'}
        end

        # Returns the default template dir for store, or default.
        #
        def template_dir(store_name)
          dirs = template_dirs
          dirs.key?(store_name) ? dirs[store_name] : dirs[:default]
        end

        def scope_attribute
          @scope_attribute || "data-scope"
        end

        def prop_attribute
          @prop_attribute || "data-prop"
        end

        def container_attribute
          @container_attribute || "data-container"
        end

      end
    end
  end
end
