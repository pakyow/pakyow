module Pakyow
  
  # Provides an easy way to log text, warnings, etc.
  class Log
    
    # Adds text to the log. 
    def self.puts(text = "")
      return if !Configuration::Base.app.log
      
      @@console ||= $stdout
      @@console << "#{text}\r\n"
      
      dir = "#{Configuration::Base.app.log_dir}"
      
      if File.exists?(dir)
        @@file ||= File.open("#{dir}/#{Configuration::Base.app.log_name}", 'a')
        @@file.write "#{text}\r\n"
      end
    end

    class << self
      alias :enter :puts
    end
    
    # Adds warning text to the log.
    def self.warn(text)
      Log.enter("WARNING: #{text}")
    end

    # Adds error text to the log.
    def self.error(text)
      Log.enter("ERROR: #{text}")
    end
  end
end
