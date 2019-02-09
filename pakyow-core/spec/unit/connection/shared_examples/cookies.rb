RSpec.shared_examples :connection_cookies do
  describe "#cookies" do
    it "returns indifferentized hash" do
      expect(connection.cookies).to be_instance_of(Pakyow::Support::IndifferentHash)
    end

    describe "the indifferent hash" do
      it "is created with cookies from Rack::Request" do
        cookies = { foo: :bar }
        allow_any_instance_of(Rack::Request).to receive(:cookies).and_return(cookies)
        expect(connection.cookies).to be_instance_of(Pakyow::Support::IndifferentHash)
      end
    end
  end
end
