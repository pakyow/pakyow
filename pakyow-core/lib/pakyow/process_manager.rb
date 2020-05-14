# frozen_string_literal: true

require "process/group"

require "pakyow/support/deprecatable"
require "pakyow/support/inflector"

require_relative "process"

module Pakyow
  # Manages one or more processes.
  #
  # @deprecated
  #
  class ProcessManager
    extend Support::Deprecatable
    deprecate

    def initialize
      @group, @stopped = ::Process::Group.new, false
    end

    # Adds a {Process} instance, where it is immediately run within this manager.
    #
    def add(process)
      if process.is_a?(Hash)
        Pakyow.deprecated "passing a `Hash' to `Pakyow::ProcessManager#add'", solution: "pass a `Pakyow::Process' instance"

        process = build_process(process)
      end

      run(process)
    end

    # Waits for all processes to exit.
    #
    def wait
      @group.wait
    end

    # Stops all processes.
    #
    def stop(signal = :INT)
      @stopped = true
      @group.kill(signal)
    end

    # Restarts all restartable processes.
    #
    def restart
      @group.running.each do |pid, process|
        if process.options[:object].restartable?
          ::Process.kill(:INT, pid)
        end
      end
    end

    private

    def run(process)
      process.count.times do
        Fiber.new {
          until @stopped
            status = @group.fork object: process do
              process.call
            rescue Interrupt
            rescue => error
              Pakyow.houston(error); exit 1
            end

            break unless status.success?
          end
        }.resume
      end
    end

    def build_process(process)
      Process.new(
        name: process[:name],
        count: process[:count],
        restartable: process[:restartable],
        &process[:block]
      )
    end
  end
end
