module Pakyow
  module Configuration
    class App
      class << self
        attr_accessor :dev_mode, :log, :public_dir, :root, :log_dir, 
        :presenter, :default_action, :ignore_routes, :error_level, 
        :default_environment, :application_path, :log_name, :src_dir,
        :auto_reload, :errors_in_browser
        
        # Displays development-specific warnings.
        #
        def dev_mode
          @dev_mode.nil? ? true : @dev_mode
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
        
        # Public directory
        def public_dir
          @public_dir || "#{root}/public"
        end
        
        # Log directory
        def log_dir
          @log_dir || "#{root}/logs"
        end

        def log_name
          @log_name || "requests.log"
        end

        def src_dir
          @src_dir || "#{root}/app/lib"
        end
        
        # Default action
        def default_action
          @default_action || :index
        end
        
        # Mockup mode
        def ignore_routes
          @ignore_routes.nil? ? false : @ignore_routes
        end
        
        def default_environment
          @default_environment || :development
        end
        
        # The path to the application class
        def application_path
          @application_path
        end
      end
    end
  end
end
