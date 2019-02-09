RSpec.describe "parsing requests" do
  before do
    Pakyow.action &action
  end

  include_context "app"

  let :action do
    Proc.new do |connection|
      connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input, params: connection.params))
    end
  end

  context "content type is application/json" do
    it "parses the input" do
      result = call("/", method: :post, input: StringIO.new(["foo", "bar"].to_json), headers: { "content-type" => "application/json" })
      expect(Marshal.load(result[2])).to eq(input: ["foo", "bar"], params: {})
    end

    context "json is a hash" do
      let :action do
        Proc.new do |connection|
          connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input, params: connection.params))
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
        end
      end

      it "parses the input" do
        result = call("/", method: :post, input: StringIO.new({ "foo" => { "bar" => "baz" } }.to_json), headers: { "content-type" => "application/json" })
        expect(Marshal.load(result[2])).to eq(input: { "foo" => {"bar" => "baz" } }, params: { foo: { bar: "baz" } })
      end
    end
  end
end
