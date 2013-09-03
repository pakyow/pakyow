module Pakyow
  module Config
    class App
      Config::Base.register_config(:app, self)

      class << self
        attr_accessor :log, :resources, :root, :log_dir,
        :default_action, :ignore_routes, :error_level,
        :default_environment, :path, :log_name, :src_dir,
        :auto_reload, :errors_in_browser, :static, :all_views_visible,
        :loaded_envs

        def method_missing(name, *args)
          if name[-1,1] == '='
            name = name[0..-2]
            instance_variable_set("@#{name}", *args)
          else
            instance_variable_get("@#{name}")
          end
        end

        def auto_reload
          @auto_reload.nil? ? true : @auto_reload
        end

        def errors_in_browser
          @errors_in_browser.nil? ? true : @errors_in_browser
        end

        # Log requests?
        def log
          @log.nil? ? true : @log
        end

        # Root directory
        def root
          @root || File.dirname('')
        end

        # Resources directory
        def resources
          @resources ||= { :default => "#{root}/public" }
        end

        # Log directory
        def log_dir
          @log_dir || "#{root}/logs"
        end

        def log_name
          @log_name || "requests.log"
        end

        def src_dir
          @src_dir || "#{root}/lib"
        end

        # Default action
        def default_action
          @default_action || :index
        end

        # Mockup mode
        def ignore_routes
          @ignore_routes.nil? ? false : @ignore_routes
        end

        def all_views_visible
          @all_views_visible.nil? ? true : @all_views_visible
        end

        def default_environment
          @default_environment || :development
        end

        # The path to the application class
        def path
          @path
        end

        # Handle static files?
        #
        # For best performance, should be set to false if static files are
        # handled by a web server (e.g. Nginx)
        #
        def static
          @static || true
        end

        def loaded_envs
          @loaded_envs
        end
      end
    end
  end
end
