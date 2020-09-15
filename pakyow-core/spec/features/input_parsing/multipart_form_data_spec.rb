RSpec.describe "parsing requests" do
  before do
    Pakyow.action(&action)
  end

  include_context "app"

  let :action do
    Proc.new do |connection|
      connection.body = StringIO.new(Marshal.dump(input: connection.parsed_input.keys, params: connection.params.keys))
      connection.halt
    end
  end

  context "content type is multipart/form-data" do
    def input
      string = String.new
      string << "--AaB03x\r\n"
      string << "Content-Type: image/png\r\n"
      string << "Content-Disposition: form-data; name=\"foo\"; filename=foo.png\r\n\r\n"
      string << "contents\r\n"
      string << "--AaB03x--\r\n"
      StringIO.new(string)
    end

    let :boundary do
      "AaB03x"
    end

    it "parses the input" do
      expect(
        Marshal.load(call(
          "/", method: :post, input: input, headers: { "content-type" => "multipart/form-data; boundary=#{boundary}" }
        )[2])
      ).to eq(input: ["foo"], params: ["foo"])
    end
  end
end
