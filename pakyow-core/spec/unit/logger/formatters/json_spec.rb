require_relative "shared"

require "pakyow/logger/formatters/json"

RSpec.describe Pakyow::Logger::Formatters::JSON do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::JSON.new(output)
  end

  it "formats the prologue" do
    formatter.call(event("prologue" => connection), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","method":"GET","uri":"/","ip":"0.0.0.0"}
      JSON
    )
  end

  it "formats the epilogue" do
    formatter.call(event("epilogue" => connection), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","status":200}
      JSON
    )
  end

  it "formats an error event" do
    formatter.call(event("error" => error), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","exception":"ArgumentError","message":"foo","backtrace":#{JSON.dump(error.backtrace)}}
      JSON
    )
  end

  it "formats an error object" do
    formatter.call(event(error), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","exception":"ArgumentError","message":"foo","backtrace":#{JSON.dump(error.backtrace)}}
      JSON
    )
  end

  it "formats a string message" do
    formatter.call(event("test"), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","message":"test"}
      JSON
    )
  end

  it "formats a hash message" do
    formatter.call(event(foo: "bar"), severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","foo":"bar"}
      JSON
    )
  end

  it "formats a string message that did not originate from Pakyow::Logger" do
    formatter.call("test", severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","message":"test"}
      JSON
    )
  end

  it "formats a hash message that did not originate from Pakyow::Logger" do
    formatter.call({ foo: "bar" }, severity: level)

    expect(entry).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","foo":"bar"}
      JSON
    )
  end
end
