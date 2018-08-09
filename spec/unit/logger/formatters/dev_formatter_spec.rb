require "unit/logger/formatters/shared"

RSpec.describe Pakyow::Logger::Formatters::Dev do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Dev.new
  end

  it "formats the prologue" do
    expect(formatter.call(severity, datetime, progname, prologue)).to eq("\e[36m 10.00ms http.123 | GET / (for 0.0.0.0 at #{datetime})\n\e[0m")
  end

  it "formats the epilogue" do
    expect(formatter.call(severity, datetime, progname, epilogue)).to eq("\e[36m 10.00ms http.123 | 200 (OK)\n\e[0m")
  end

  it "formats an error" do
    expect(formatter.call(severity, datetime, progname, error)).to eq("\e[36m 10.00ms http.123 | ArgumentError: foo\n                       | one\n                       | two\n\e[0m")
  end

  it "formats a message" do
    expect(formatter.call(severity, datetime, progname, message)).to eq("\e[36m 10.00ms http.123 | foo\n\e[0m")
  end
end
