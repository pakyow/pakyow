RSpec.shared_examples :connection_params do
  describe "#params" do
    it "is a Params instance"

    it "includes query params" do
      expect(connection.params[:foo]).to eq("bar")
    end

    context "input parser is available that adds params" do
      before do
        allow(connection.instance_variable_get(:@request)).to receive(:body).and_return(
          body
        )

        connection.input_parser = {
          block: Proc.new { |input, connection|
            connection.params.add("baz", "qux")
          }
        }
      end

      let :body do
        Async::HTTP::Body::Buffered.wrap(StringIO.new("foo"))
      end

      it "includes the input parser params" do
        expect(connection.params[:baz]).to eq("qux")
      end

      context "input params conflict with query params" do
        before do
          connection.input_parser = {
            block: Proc.new { |input, connection|
              connection.params.add("foo", "input_bar")
            }
          }
        end

        it "prioritizes the input param" do
          expect(connection.params[:foo]).to eq("input_bar")
        end
      end
    end
  end
end
