module Pakyow
  
  # Provides an easy way to log text, warnings, etc.
  class Log
    # Opens stdout and the log file for writing.
    def self.reopen
      @@console = $stdout

      d = Config::Base.app.log_dir
      @@file = File.exists?(d) ? File.open("#{d}/#{Config::Base.app.log_name}", 'a') : nil
      @@file.sync = true if @@file
    end

    def self.close
      @@file.close if @@file
    end

    # Adds text to the log. 
    def self.puts(text = "")
      return if !Config::Base.app.log
      
      @@console << "#{text}\r\n"
      @@file.write "#{text}\r\n" if @@file
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
