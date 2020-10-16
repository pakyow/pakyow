RSpec.shared_examples :connection_sleep do
  describe "#sleep" do
    it "sleeps the current async task" do
      Async::Reactor.run { |task|
        expect(task).to receive(:sleep).with(0.1)
        connection.sleep(0.1)
      }.wait
    end
  end
end
