RSpec.shared_examples :connection_input do
  before do
    allow(connection.instance_variable_get(:@request)).to receive(:body).and_return(
      body
    )
  end

  let :body do
    Async::HTTP::Body::Buffered.wrap(StringIO.new("foo"))
  end

  describe "#input" do
    it "returns the request body" do
      expect(connection.input).to be(body)
    end
  end

  describe "#parsed_input" do
    context "input parser is defined" do
      before do
        connection.input_parser = Proc.new do |*args|
          args[0].read
          @input_parser_args = args
          "foo"
        end
      end

      it "calls the input parser" do
        connection.parsed_input
        expect(@input_parser_args[0]).to eq(connection.instance_variable_get(:@request).body)
        expect(@input_parser_args[1]).to be(connection)
      end

      it "returns the result of the input parser" do
        expect(connection.parsed_input).to eq("foo")
      end

      it "rewinds the input" do
        connection.parsed_input
        expect(connection.input.read).to eq("foo")
      end
    end

    context "no input parser is defined" do
      it "returns nil" do
        expect(connection.parsed_input).to be(nil)
      end
    end

    describe "calling multiple times" do
      before do
        @calls = []

        connection.input_parser = Proc.new do |*args|
          @calls << :called
          "foo"
        end

        connection.parsed_input
        connection.parsed_input
        connection.parsed_input
      end

      it "only calls the input parser once" do
        expect(@calls.count).to eq(1)
      end

      it "memoizes the parsed input value" do
        expect(connection.parsed_input).to eq("foo")
      end
    end
  end
end
