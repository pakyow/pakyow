# frozen_string_literal: true

require "process/group"

require "pakyow/support/inflector"

module Pakyow
  class ProcessManager
    def initialize
      @group, @processes, @stopped = Process::Group.new, [], false
    end

    def add(process)
      process = process.dup
      run_process(process)
      @processes << process
    end

    def wait
      @group.wait
    end

    def stop(signal = :INT)
      @stopped = true
      @group.kill(signal)
    end

    def restart
      @group.running.each do |pid, forked|
        if forked.instance_variable_get(:@options)[:restartable]
          Process.kill(:INT, pid)
        end
      end
    end

    private

    def run_process(process)
      Fiber.new {
        until @stopped
          status = @group.fork(process) {
            begin
              Async::Reactor.run(process, &process[:block])
            rescue Interrupt
            end
          }

          break unless status.success?
        end
      }.resume
    end
  end
end
