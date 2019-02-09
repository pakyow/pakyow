require_relative "shared"

require "pakyow/logger/formatters/human"

RSpec.describe Pakyow::Logger::Formatters::Human do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Human.new
  end

  it "formats the prologue" do
    expect(formatter.format(event(prologue: connection))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | GET / (for 0.0.0.0 at #{Time.now})\e[0m
      STRING
    )
  end

  it "formats the epilogue" do
    expect(formatter.format(event(epilogue: connection))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | 200 (OK)\e[0m
      STRING
    )
  end

  it "formats an error event" do
    allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return(error.to_s)
    expect(formatter.format(event(error: error))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | foo\e[0m
      STRING
    )
  end

  it "formats an error object" do
    allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return(error.to_s)
    expect(formatter.format(event(error))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | foo\e[0m
      STRING
    )
  end

  it "formats a string message" do
    expect(formatter.format(event("test"))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | test\e[0m
      STRING
    )
  end

  it "formats a hash message" do
    expect(formatter.format(event(foo: "bar"))).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | {:foo=>\"bar\"}\e[0m
      STRING
    )
  end

  it "formats a string message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: "test"))).to eq(
      <<~STRING
        \e[32mtest\e[0m
      STRING
    )
  end

  it "formats a hash message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: { foo: "bar" }))).to eq(
      <<~STRING
        \e[32m{:foo=>\"bar\"}\e[0m
      STRING
    )
  end
end
