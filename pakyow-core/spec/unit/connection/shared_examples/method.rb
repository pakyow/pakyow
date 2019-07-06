RSpec.shared_examples :connection_method do
  describe "#method" do
    it "is proper formatted" do
      expect(connection.method).to eq :get
    end

    context "override is passed as a param" do
      before do
        connection.params.add(:"pw-http-method", "DELETE")
      end

      context "request method is post" do
        let :method do
          "POST"
        end

        it "uses the override" do
          expect(connection.method).to eq :delete
        end
      end

      context "request method is not post" do
        let :method do
          "PUT"
        end

        it "ignores the override" do
          expect(connection.method).to eq :put
        end
      end
    end
  end
end
