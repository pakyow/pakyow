require_relative "shared"

require "pakyow/logger/formatters/logfmt"

RSpec.describe Pakyow::Logger::Formatters::Logfmt do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Logfmt.new
  end

  it "formats the prologue" do
    expect(formatter.format_prologue(connection)).to eq(
      method: "GET",
      uri: "/",
      ip: "0.0.0.0"
    )
  end

  it "formats the epilogue" do
    expect(formatter.format_epilogue(connection)).to eq(
      status: 200
    )
  end

  it "formats an error" do
    expect(formatter.format_error(error)).to eq(
      exception: error.class,
      message: error.to_s,
      backtrace: error.backtrace
    )
  end

  it "formats a string message" do
    expect(
      formatter.call(severity, datetime, progname, "foo")
    ).to eq("severity=DEBUG timestamp=\"#{datetime}\" message=foo\n")
  end

  it "formats a hash message" do
    expect(
      formatter.call(severity, datetime, progname, foo: "bar")
    ).to eq("severity=DEBUG timestamp=\"#{datetime}\" foo=bar\n")
  end
end
