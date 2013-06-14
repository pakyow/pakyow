module Pakyow
  module Config
    class Presenter
      Config::Base.register_config(:presenter, self)

      class << self
        attr_accessor :view_caching, :javascripts, :stylesheets, :view_stores, :default_views,
        :scope_attribute, :prop_attribute, :container_attribute
        
        # Location of javascripts
        def javascripts
          @javascripts || '/javascripts'
        end
        
        # Location of stylesheets
        def stylesheets
          @stylesheets || '/stylesheets'
        end

        def view_stores
          @view_stores ||= {:default => "#{Config::Base.app.root}/views"}
        end
        
        def view_caching
          @view_caching || false
        end

        def default_views
          @default_views ||= {:default => "pakyow.html"}
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
