require 'fileutils'

module Pakyow
  module Generators
    class AppGenerator
      class << self
        def start
          case ARGV.first
          when '--help', '-h', nil
            puts File.open(File.join(PAK_PATH, 'commands/USAGE-NEW')).read
          else
            generator = self.new(ARGV.first)
            generator.build
          end
        end
      end

      def initialize(dest)
        @src = "#{File.expand_path('../', __FILE__)}/templates/."
        @dest = dest
      end

      def build
        puts "Generating project: #{@dest}"

        if !File.directory?(@dest) || (Dir.entries(@dest) - ['.', '..']).empty?
          copy
        else
          ARGV.clear
          print "The folder '#{@dest}' is in use. Would you like to populate it anyway? [Yn] "

          if gets.chomp! == 'Y'
            copy
          else
            puts "Aborted!"
            exit
          end
        end

        exec
        puts "Done! Run `cd #{@dest}; pakyow server` to get started!"
      end

      protected

      # copies src files to dest
      def copy
        FileUtils.cp_r(@src, @dest)
      end

      # performs and other setup (e.g. bundle install)
      def exec
        FileUtils.cd(@dest) do
          puts "Running `bundle install` in #{Dir.pwd}"
          system("bundle install")
        end
      end
    end
  end
end
