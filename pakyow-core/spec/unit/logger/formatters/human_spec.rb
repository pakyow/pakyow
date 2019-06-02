require_relative "shared"

require "pakyow/logger/formatters/human"

RSpec.describe Pakyow::Logger::Formatters::Human do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Human.new(output)
  end

  it "formats the prologue" do
    formatter.call(event("prologue" => connection), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | GET / (for 0.0.0.0 at #{Time.now})\e[0m
      STRING
    )
  end

  it "formats the epilogue" do
    formatter.call(event("epilogue" => connection), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | 200 (OK)\e[0m
      STRING
    )
  end

  it "formats an error event" do
    allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return(error.to_s)
    formatter.call(event("error" => error), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | foo\e[0m
      STRING
    )
  end

  it "formats an error object" do
    allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return(error.to_s)
    formatter.call(event(error), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | foo\e[0m
      STRING
    )
  end

  it "formats a string message" do
    formatter.call(event("test"), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | test\e[0m
      STRING
    )
  end

  it "formats a hash message" do
    formatter.call(event(foo: "bar"), severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m420.00μs test.123 | {:foo=>\"bar\"}\e[0m
      STRING
    )
  end

  it "formats a string message that did not originate from Pakyow::Logger" do
    formatter.call("test", severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32mtest\e[0m
      STRING
    )
  end

  it "formats a hash message that did not originate from Pakyow::Logger" do
    formatter.call({ foo: "bar" }, severity: level)

    expect(entry).to eq(
      <<~STRING
        \e[32m{:foo=>\"bar\"}\e[0m
      STRING
    )
  end
end
