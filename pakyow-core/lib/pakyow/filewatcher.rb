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
          @watched << path; true
        end
      end
    end

    # Ignore changes at `path`.
    #
    def ignore(path)
      path = File.expand_path(path)

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
        @callbacks << Callback.new(matcher, snapshot: snapshot, &block)
      end
    end

    # Runs the filewatcher.
    #
    def perform
      run
    end
    alias start perform

    # Stops the filewatcher.
    #
    def stop
      @status.stopped!
    end
    alias shutdown stop

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
        snapshot = build_snapshot(@watched)

        Pakyow.async do |task|
          until @status.stopped?
            task.sleep(@interval)

            if @status.running?
              # Rebuild the snapshot if watched paths have changed.
              #
              unless snapshot.paths == @watched
                snapshot = build_snapshot(@watched)
              end

              # Always rebuild what we're ignoring to update based on latest @ignored and filesystem.
              #
              ignoring = build_snapshot(@ignored)

              # Lets us keep track of callbacks that were called in this tick.
              #
              called_callbacks = []

              # Look for changes.
              #
              snapshot = detect_changes!(snapshot) do |(path, event), diff|
                # Double check that we haven't paused or stopped when processing each change.
                #
                if @status.running?
                  @callbacks.each do |callback|
                    if callback.matches?(path) && !ignoring.include?(path)
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
              end
            end
          end
        end
      end
    end

    # @api private
    private def build_snapshot(watched)
      Snapshot.new(*watched)
    end

    # @api private
    private def detect_changes!(snapshot, &block)
      latest = build_snapshot(snapshot.paths)
      diff = snapshot.diff(latest)
      diff.each_pair.each_with_object(diff, &block)
      latest
    end
  end
end
