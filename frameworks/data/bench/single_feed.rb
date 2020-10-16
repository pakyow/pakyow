# frozen_string_literal: true

# Benchmarks sending a message to many subscribers of a single feed.
# Treats each feed as separate, though each presents the same dataset.

Bundler.require :default

ENV["SESSION_SECRET"] = "foobar"

class BenchHandler
  def initialize(app)
    @app = app
  end

  def call(_payload)
    File.open("./calls.txt", "a+") do |file|
      file.write(Time.now.to_f.to_s + "\n")
    end
  end
end

Pakyow.app :single_feed_benchmark, only: %i[core data] do
  resource :messages, "/messages" do
    disable_protection :csrf

    create do
      verify do
        required :message do
          required :content
        end
      end

      data.messages.create(params[:message])
    end

    collection do
      get "/subscribe/:subscriber" do
        data.messages.subscribe(params[:subscriber], payload: {current_time: Time.now}, handler: BenchHandler)
      end

      get "/unsubscribe/:subscriber" do
        data.subscribers.unsubscribe(params[:subscriber])
      end
    end
  end

  source :messages do
    primary_id
    timestamps
    attribute :content

    query :ordered_and_limited

    def ordered_and_limited
      order(created_at: :desc).limit(10)
    end
  end
end

Pakyow.configure do
  config.data.auto_migrate = true
  config.data.connections.sql[:default] = "sqlite://"
end

@pid = fork {
  Pakyow.setup(env: :production).run(port: 4242, host: "localhost")
}

require "fileutils"

def run_benchmark(subscriber_count)
  FileUtils.rm_f("./calls.txt")

  puts "creating #{subscriber_count} subscribers..."
  subscriber_count.times do |i|
    HTTP.get("http://localhost:4242/messages/subscribe/#{i}")
  end

  puts "DONE; sending a message..."
  start = Time.now
  HTTP.post("http://localhost:4242/messages", json: {message: {content: "one"}})
  elapsed = Time.now - start

  puts "DONE; checking for messages..."
  completed_count = 0
  until completed_count >= subscriber_count
    sleep 1
    completed_count = `wc -l ./calls.txt`.strip.split(" ")[0].to_i
    puts "completed #{completed_count} of #{subscriber_count}"
  end

  puts "DONE; removing #{subscriber_count} subscribers..."
  subscriber_count.times do |i|
    HTTP.get("http://localhost:4242/messages/unsubscribe/#{i}")
  end

  puts "DONE"

  elapsed
end

# wait for the app to start
sleep 3

elapsed = run_benchmark(10_000)
puts "sent message in: #{elapsed}s"

# TODO: other things to measure
#   - overall memory usage of server process, redis
#   - how long it takes to send a message
#   - how many keys exist per subscriber
#      - that keys decrease after unsubscribing
#   - how many total queries are executed

sleep 1

Process.kill("TERM", @pid)
