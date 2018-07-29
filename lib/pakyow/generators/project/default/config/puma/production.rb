# frozen_string_literal: true

# Describes how the application server operates in production.
#
# Learn more about Puma:
#
#   * https://puma.io/
#
workers_count = ENV.fetch("WORKERS", 3)
threads_count = ENV.fetch("THREADS", 5)

workers workers_count
threads threads_count, threads_count

on_worker_boot do
  Pakyow.booted
end
