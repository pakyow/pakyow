RSpec.describe "parsing requests" do
  before do
    Pakyow.action(&action)
  end

  include_context "app"

  let :action do
    Proc.new do |connection|
      connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input, params: connection.params))
      connection.halt
    end
  end

  context "content type is application/x-www-form-urlencoded" do
    it "parses the input" do
      expect(
        Marshal.restore(
          call("/", method: :post, input: StringIO.new("foo=bar"), headers: { "content-type" => "application/x-www-form-urlencoded" })[2]
        )
      ).to eq(input: { foo: "bar" }, params: { foo: "bar" })
    end
  end
end
