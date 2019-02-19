require_relative "shared"

require "pakyow/logger/formatters/human"

RSpec.describe Pakyow::Logger::Formatters::Human do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::Human.new
  end

  it "formats the prologue" do
    expect(formatter.format_prologue(connection)).to eq("GET / (for 0.0.0.0 at #{datetime})")
  end

  it "formats the epilogue" do
    expect(formatter.format_epilogue(connection)).to eq("200 (OK)")
  end

  it "formats an error" do
    allow_any_instance_of(Pakyow::Error::CLIFormatter).to receive(:to_s).and_return("error")
    expect(formatter.format_error(error)).to eq("error")
  end

  it "formats a string message" do
    expect(
      formatter.call(severity, datetime, progname, "foo")
    ).to eq("\e[36mfoo\e[0m\n")
  end

  it "formats a hash message" do
    expect(
      formatter.call(severity, datetime, progname, foo: "bar")
    ).to eq("\e[36m{:foo=>\"bar\"}\e[0m\n")
  end
end
