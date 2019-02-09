require_relative "shared"

require "pakyow/logger/formatters/logfmt"

RSpec.describe Pakyow::Logger::Formatters::Logfmt do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Logfmt.new
  end

  it "formats the prologue" do
    expect(formatter.format(event(prologue: connection))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms method=GET uri=/ ip=0.0.0.0
      STRING
    )
  end

  it "formats the epilogue" do
    expect(formatter.format(event(epilogue: connection))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms status=200
      STRING
    )
  end

  it "formats an error event" do
    expect(formatter.format(event(error: error))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms exception=ArgumentError message=foo backtrace="#{error.backtrace.join(",")}"
      STRING
    )
  end

  it "formats an error object" do
    expect(formatter.format(event(error))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms exception=ArgumentError message=foo backtrace="#{error.backtrace.join(",")}"
      STRING
    )
  end

  it "formats a string message" do
    expect(formatter.format(event("test"))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms message=test
      STRING
    )
  end

  it "formats a hash message" do
    expect(formatter.format(event(foo: "bar"))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" id=123 type=test elapsed=0.42ms foo=bar
      STRING
    )
  end

  it "formats a string message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: "test"))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" message=test
      STRING
    )
  end

  it "formats a hash message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: { foo: "bar" }))).to eq(
      <<~STRING
        severity=info timestamp="#{Time.now}" foo=bar
      STRING
    )
  end
end
