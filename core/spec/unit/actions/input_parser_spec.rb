RSpec.describe Pakyow::Actions::InputParser do
  let :action do
    described_class.new
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    instance_double(
      Async::HTTP::Protocol::Request,
      body: Protocol::HTTP1::Body::Fixed.new(
        Async::IO::Stream.new(
          StringIO.new(body)
        ), body.bytesize
      ),
      headers: { "content-type" => "text/foo" },
      :body= => nil
    )
  end

  let :body do
    "foo"
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:output, level: 2, verbose!: nil)
    )
  end

  context "parser is registered for the request type" do
    before do
      Pakyow.parse_input "text/foo" do |body|
        body.read.upcase
      end
    end

    context "connection body is not empty" do
      it "sets the input_parser on the connection" do
        expect(connection).to receive(:input_parser=)
        action.call(connection)
      end

      describe "parsing the input" do
        it "parses" do
          action.call(connection)
          expect(connection.parsed_input).to eq("FOO")
        end
      end
    end

    context "connection body is empty" do
      let :body do
        ""
      end

      it "does not set the input parser on the connection" do
        expect(connection).not_to receive(:input_parser=)
        action.call(connection)
      end
    end
  end

  context "parser is registered, but not for the type" do
    before do
      Pakyow.parse_input "text/bar" do |body|
      end
    end

    it "does not set the input parser on the connection" do
      expect(connection).not_to receive(:input_parser=)
      action.call(connection)
    end
  end

  context "no parsers are registered" do
    it "does not set the input parser on the connection" do
      expect(connection).not_to receive(:input_parser=)
      action.call(connection)
    end
  end
end
