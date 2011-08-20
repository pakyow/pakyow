module Pakyow
  
  # Provides an easy way to log text, warnings, etc.
  class Log
    
    # Adds text to the log. 
    def self.puts(text = "")
      return if !Configuration::Base.app.log
      
      @@console ||= Logger.new($stdout)
      @@console << "#{text}\r\n"
      
      dir = "#{Configuration::Base.app.log_dir}"
      
      if File.exists?(dir)
        @@file ||= Logger.new("#{dir}/#{Configuration::Base.app.log_name}")
        @@file    << "#{text}\r\n"
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
