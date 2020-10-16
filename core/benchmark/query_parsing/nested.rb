require "benchmark/ips"

require "pakyow/connection/query_parser"
require "rack/query_parser"
require "rack/utils"

query = "data[books][][data][page]=1&data[books][][data][page]=2"

Benchmark.ips do |x|
  x.config(time: 5, warmup: 1)

  x.report("Nested Query Parsing (Pakyow)") do
    parser = Pakyow::Connection::QueryParser.new
    parser.parse(query)
  end

  x.report("Nested Query Parsing (Rack)") do
    parser = Rack::QueryParser.make_default(65536, 100)
    parser.parse_nested_query(query)
  end

  x.compare!
end
