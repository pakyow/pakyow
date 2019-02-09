require "benchmark/ips"

require "pakyow/connection/query_parser"
require "rack/query_parser"
require "rack/utils"

query = "foo=bar"

Benchmark.ips do |x|
  x.config(time: 5, warmup: 1)

  x.report("Simple Query Parsing (Pakyow)") do
    parser = Pakyow::Connection::QueryParser.new
    parser.parse(query)
  end

  x.report("Simple Query Parsing (Rack)") do
    parser = Rack::QueryParser.make_default(65536, 100)
    parser.parse_nested_query(query)
  end

  x.compare!
end
