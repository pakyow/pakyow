RSpec.shared_examples :connection_stream do
  describe "#stream" do
    it "sets a writable body" do
      Async::Reactor.run {
        expect {
          connection.stream do; end
        }.to change {
          connection.body.class
        }.from(Async::HTTP::Body::Buffered).to(Async::HTTP::Body::Writable)
      }.wait
    end

    it "sets the body length to nil by default" do
      Async::Reactor.run {
        connection.stream do; end
      }.wait

      expect(connection.body.length).to be(nil)
    end

    it "registers an async task that yields the connection" do
      Async::Reactor.run { |task|
        expect(task).to receive(:async) do |&block|
          block.call
        end

        expect { |b|
          connection.stream &b
        }.to yield_with_args(connection)
      }.wait
    end

    context "length is passed" do
      before do
        Async::Reactor.run {
          connection.stream(42) do; end
        }.wait
      end

      it "sets the body length appropriately" do
        expect(connection.body.length).to eq(42)
      end
    end

    context "called again" do
      it "does not override the current writable body" do
        Async::Reactor.run {
          connection.stream do; end
          body = connection.body
          connection.stream do; end
          expect(connection.body).to be(body)
        }.wait
      end
    end
  end

  describe "#streaming?" do
    context "nothing is streaming" do
      it "returns false" do
        expect(connection.streaming?).to be(false)
      end
    end

    context "something is streaming" do
      it "returns true" do
        Async::Reactor.run { |task|
          connection.stream do; end

          connection.stream do
            connection.sleep 0.02
          end

          task.sleep 0.01

          expect(connection.streaming?).to be(true)
        }.wait
      end
    end

    context "streams finish" do
      it "returns false" do
        Async::Reactor.run { |task|
          connection.stream do
            connection.sleep 0.01
          end

          task.sleep 0.02

          expect(connection.streaming?).to be(false)
        }.wait
      end
    end
  end
end
