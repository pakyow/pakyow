RSpec.describe "parsing requests" do
  before do
    Pakyow.action &action
  end

  include_context "app"

  let :action do
    Proc.new do |connection|
      connection.body = StringIO.new(
        Marshal.dump(
          input: connection.parsed_input,
          params: connection.params,
          rewindable: connection.request.body.respond_to?(:rewind)
        )
      )

      connection.halt
    end
  end

  context "content type is application/json" do
    let :result do
      Marshal.load(call("/", method: :post, input: StringIO.new(["foo", "bar"].to_json), headers: { "content-type" => "application/json" })[2])
    end

    it "parses the input" do
      expect(result[:input]).to eq(["foo", "bar"])
    end

    it "sets the params" do
      expect(result[:params]).to eq({})
    end

    it "it makes the request body rewindable" do
      expect(result[:rewindable]).to eq(true)
    end

    context "json is a hash" do
      let :action do
        Proc.new do |connection|
          connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input, params: connection.params))
          connection.halt
        end
      end

      it "parses the input" do
        result = call("/", method: :post, input: StringIO.new({ "foo" => "bar" }.to_json), headers: { "content-type" => "application/json" })
        expect(Marshal.load(result[2])).to eq(input: { "foo" => "bar" }, params: { foo: "bar" })
      end
    end

    context "json is a deeply nested hash" do
      let :action do
        Proc.new do |connection|
          connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input, params: connection.params))
          connection.halt
        end
      end

      it "parses the input" do
        result = call("/", method: :post, input: StringIO.new({ "foo" => { "bar" => "baz" } }.to_json), headers: { "content-type" => "application/json" })
        expect(Marshal.load(result[2])).to eq(input: { "foo" => {"bar" => "baz" } }, params: { foo: { bar: "baz" } })
      end

      it "deeply indifferentizes hashes nested in arrays" do
        result = call("/", method: :post, input: StringIO.new({ "foo" => [{ "bar" => "baz" }] }.to_json), headers: { "content-type" => "application/json" })
        expect(Marshal.load(result[2])[:params][:foo][0]).to be_instance_of(Pakyow::Support::IndifferentHash)
      end
    end
  end
end
