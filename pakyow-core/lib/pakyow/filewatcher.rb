# frozen_string_literal: true

require "async"

require "pakyow/support/inspectable"

module Pakyow
  # Watches the filesystem, calling callbacks when something changes.
  #
  class Filewatcher
    require "pakyow/filewatcher/callback"
    require "pakyow/filewatcher/diff"
    require "pakyow/filewatcher/snapshot"
    require "pakyow/filewatcher/status"

    include Support::Inspectable
    inspectable :@status, :@interval

    # The current configured interval.
    #
    attr_reader :interval

    def initialize(interval: 0.1)
      @interval = interval
      @watched = []
      @ignored = []
      @callbacks = []
      @status = Status.new
      @lock = Mutex.new
    end

    # Watch `path` for changes.
    #
    def watch(path)
      path = File.expand_path(path)

      @lock.synchronize do
        unless @watched.include?(path)
          @watched << path
          true
        end
      end
    end

    # Ignore changes at `path`.
    #
    def ignore(path)
      path = case path
      when String
        File.expand_path(path)
      else
        path
      end

      @lock.synchronize do
        unless @ignored.include?(path)
          @ignored << path
        end
      end
    end

    # Register a callback to be called when a change is detected. If `matcher` is passed, the
    # callback will only be called for matching changes. The matcher can be a string or any object
    # that responds to `match?`. By default, the callback is called for all changes. If `snapshot`
    # is `true`, the callback will only be called once per tick.
    #
    def callback(matcher = nil, snapshot: false, &block)
      @lock.synchronize do
        @callbacks << Callback.build(matcher, snapshot: snapshot, &block)
      end
    end

    # Runs the filewatcher.
    #
    def perform
      run
    end
    alias_method :start, :perform

    # Stops the filewatcher.
    #
    def stop
      @status.stopped!
    end
    alias_method :shutdown, :stop

    # Pauses the filewatcher.
    #
    def pause
      @status.paused!
    end

    # Resumes the filewatcher.
    #
    def resume
      @status.running!
    end

    # @api private
    private def run
      @status.running! do
        snapshot = build_snapshot(@watched, @ignored)

        Pakyow.async do |task|
          until @status.stopped?
            task.sleep(@interval)

            if @status.running?
              # Rebuild the snapshot if watched paths have changed.
              #
              unless snapshot.paths == @watched && snapshot.ignored == @ignored
                snapshot = build_snapshot(@watched, @ignored)
              end

              # Lets us keep track of callbacks that were called in this tick.
              #
              called_callbacks = []

              # Look for changes.
              #
              snapshot = detect_changes(snapshot) { |(path, event), diff|
                # Double check that we haven't paused or stopped when processing each change.
                #
                if @status.running?
                  @callbacks.each do |callback|
                    if callback.match?(path)
                      if callback.snapshot?
                        unless called_callbacks.include?(callback)
                          called_callbacks << callback
                          callback.call(diff)
                        end
                      else
                        callback.call(path, event)
                      end
                    end
                  end
                end
              }
            end
          end
        end
      end
    end

    # @api private
    private def build_snapshot(watched_paths, ignored_paths_and_regexps)
      Snapshot.new(*watched_paths, ignored: ignored_paths_and_regexps)
    end

    # @api private
    private def detect_changes(current_snapshot, &block)
      latest_snapshot = build_snapshot(current_snapshot.paths, current_snapshot.ignored)

      diff = current_snapshot.diff(latest_snapshot)
      diff.each_pair.each_with_object(diff, &block)

      latest_snapshot
    end
  end
end
