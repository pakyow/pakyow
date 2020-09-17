RSpec.describe "parsing requests" do
  before do
    Pakyow.parse_input "application/foo", &input_parser
    Pakyow.action(&action)
  end

  let :input_parser do
    Proc.new do |input, connection|
      connection.body = StringIO.new(input.read.reverse)
    end
  end

  let :action do
    Proc.new do |connection|
      connection.parsed_input
      connection.halt
    end
  end

  include_context "app"

  let(:allow_request_failures) {
    true
  }

  it "is possible to define a connection parser" do
    expect(call("/", method: :post, headers: { "content-type" => "application/foo" }, input: StringIO.new("foo"))[2]).to eq("oof")
  end

  context "input parsing fails" do
    before do
      Pakyow.parse_input "application/foo" do |input, connection|
        fail
      end
    end

    it "responds 500" do
      expect(call("/", method: :post, headers: { "content-type" => "application/foo" }, input: StringIO.new("foo"))[0]).to eq(500)
    end
  end

  context "parsed input is not accessed" do
    let :input_parser do
      @called = false
      Proc.new do
        @called = true
      end
    end

    let :action do
      Proc.new do; end
    end

    it "does not parse the input" do
      call("/", method: :post, headers: { "content-type" => "application/foo" }, input: StringIO.new("foo"))
      expect(@called).to be(false)
    end
  end

  context "input is nil" do
    let :input_parser do
      @called = false
      Proc.new do
        @called = true
      end
    end

    it "does not parse the input" do
      call("/", method: :post, headers: { "content-type" => "application/foo" })
      expect(@called).to be(false)
    end
  end
end
