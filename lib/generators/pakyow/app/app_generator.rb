require 'erb'
require 'fileutils'
require 'securerandom'
require 'pakyow/version.rb'

module Pakyow
  # @api private
  module Generators
    class AppGenerator < Thor
      include Thor::Actions

      class << self
        def start(destination)
          generator = self.new(destination)
          generator.build
        end
      end

      FILENAME_TRANSLATIONS = {
        'rspec' => '.rspec',
        'gitignore' => '.gitignore',
        'env' => '.env',
        'env.example' => '.env.example'
      }

      def initialize(dest)
        @src = "templates"
        @dest = dest
        # if any of the below is not set, an error will result
        self.options ||= {}
        self.destination_root = "/"
        Pakyow::Generators::AppGenerator.source_root(File.expand_path('../', __FILE__))
      end


      no_commands {
        def build
          puts "Generating project: #{@dest}"
          dest_path = File.expand_path @dest

          if !File.directory?(@dest) || (Dir.entries(@dest) - ['.', '..']).empty?
            # copy
            directory @src, dest_path
          else
            ARGV.clear
            print "The folder '#{@dest}' is in use. Would you like to populate it anyway? [Yn] "

            if gets.chomp! == 'Y'
              # copy
              directory @src, dest_path
            else
              puts "Aborted!"
              exit
            end
          end

          exec
          puts "Done! Run `cd #{@dest}; bundle exec pakyow server` to get started!"
        end

        def dot
          "."
        end
      }

      protected

      def copy
        FileUtils.mkdir(@dest) unless File.exists?(@dest)

        Dir.glob(File.join(@src, '**', '*')).each do |path|
          relative_path = path[@src.length..-1]
          generated_path = File.join(@dest, File.dirname(relative_path), translated_filename(File.basename(relative_path)))

          if File.directory?(path)
            FileUtils.mkdir(generated_path)
            next
          end

          erb = ERB.new(File.read(path))
          File.open(generated_path, 'w') { |f| f.write(erb.result(binding)) }
        end
      end

      def exec
        FileUtils.cd(@dest) do
          puts "Running `bundle install` in #{Dir.pwd}"
          system("bundle install --binstubs")
        end
      end

      def generating_locally?
        local_pakyow = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }.detect{|k,v| k == 'pakyow'}
        !local_pakyow || local_pakyow.last.last.version < Gem::Version.new(Pakyow::VERSION)
      end

      def translated_filename(filename)
        FILENAME_TRANSLATIONS.fetch(filename, filename)
      end

      def generate_session_secret
        SecureRandom.hex(64)
      end

      def app_name
        File.basename(@dest)
      end
    end
  end
end
