# frozen_string_literal: true

module Pakyow
  class Filewatcher
    # Represents the changes encountered in one tick of a filewatcher.
    #
    class Snapshot
      # The paths this snapshot contains changes for.
      #
      attr_reader :paths

      def initialize(*paths)
        @paths = paths.freeze

        @mtimes = Hash[
          paths.flat_map { |watch|
            mtime_glob(watch)
          }
        ].freeze
      end

      # Returns `true` if `path` is included in this snapshot.
      #
      def include?(path)
        @mtimes.include?(path)
      end

      # Returns the modified time for `path`, or `nil` if `path` is not included in this snapshot.
      #
      def mtime(path)
        @mtimes[path]
      end

      # Yields each changed path and modified time.
      #
      def each_change(&block)
        return to_enum(:each_change) unless block_given?

        @mtimes.each_pair(&block)
      end
      alias each_pair each_change

      # Yields each changed path.
      #
      def each_changed_path(&block)
        return to_enum(:each_changed_path) unless block_given?

        @mtimes.each_key(&block)
      end

      # @api private
      def diff(snapshot)
        diff = Diff.new

        each_change do |path, mtime|
          if snapshot.include?(path)
            if snapshot.mtime(path) != mtime
              diff.changed(path)
            end
          else
            diff.removed(path)
          end
        end

        snapshot.each_change do |path, _mtime|
          unless include?(path)
            diff.added(path)
          end
        end

        diff
      end

      # @api private
      private def mtime_glob(path)
        Dir.glob(File.directory?(path) ? File.join(path, "*") : path).map { |globbed_path|
          [globbed_path, File.mtime(globbed_path)]
        }
      end
    end
  end
end
