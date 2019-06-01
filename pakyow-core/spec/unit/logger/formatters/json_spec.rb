require_relative "shared"

require "pakyow/logger/formatters/json"

RSpec.describe Pakyow::Logger::Formatters::JSON do
  include_examples :log_formatter

  let :formatter do
    Pakyow::Logger::Formatters::JSON.new
  end

  it "formats the prologue" do
    expect(formatter.format(event("prologue" => connection))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","method":"GET","uri":"/","ip":"0.0.0.0"}
      JSON
    )
  end

  it "formats the epilogue" do
    expect(formatter.format(event("epilogue" => connection))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","status":200}
      JSON
    )
  end

  it "formats an error event" do
    expect(formatter.format(event("error" => error))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","exception":"ArgumentError","message":"foo","backtrace":#{JSON.dump(error.backtrace)}}
      JSON
    )
  end

  it "formats an error object" do
    expect(formatter.format(event(error))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","exception":"ArgumentError","message":"foo","backtrace":#{JSON.dump(error.backtrace)}}
      JSON
    )
  end

  it "formats a string message" do
    expect(formatter.format(event("test"))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","message":"test"}
      JSON
    )
  end

  it "formats a hash message" do
    expect(formatter.format(event(foo: "bar"))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","id":"123","type":"test","elapsed":"0.42ms","foo":"bar"}
      JSON
    )
  end

  it "formats a string message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: "test"))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","message":"test"}
      JSON
    )
  end

  it "formats a hash message that did not originate from Pakyow::Logger" do
    expect(formatter.format(double(:event, level: level, data: { foo: "bar" }))).to eq(
      <<~JSON
        {"severity":"info","timestamp":"#{Time.now}","foo":"bar"}
      JSON
    )
  end
end
