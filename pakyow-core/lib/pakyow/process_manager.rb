# frozen_string_literal: true

require "process/group"

require "pakyow/process"

require "pakyow/support/inflector"

module Pakyow
  class ProcessManager
    def initialize
      @group, @stopped = ::Process::Group.new, false
    end

    def add(process)
      if process.is_a?(Hash)
        Pakyow.deprecated "passing a `Hash' to `Pakyow::ProcessManager#add'", "pass a `Pakyow::Process' instance"

        process = build_process(process)
      end

      run(process)
    end

    def wait
      @group.wait
    end

    def stop(signal = :INT)
      @stopped = true
      @group.kill(signal)
    end

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
              Async do
                process.call
              rescue => error
                Pakyow.logger.houston(error)
                exit 1
              end
            rescue Interrupt
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
