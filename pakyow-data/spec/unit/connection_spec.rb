RSpec.describe Pakyow::Data::Connection do
  describe "::parse_connection_string" do
    let :connection_string do
      "postgres://test:testpw@localhost:5432/pakyow-test?timeout=1"
    end

    let :parsed do
      described_class.parse_connection_string(connection_string)
    end

    it "parses the adapter" do
      expect(parsed[:adapter]).to eq("postgres")
    end

    it "parses the path" do
      expect(parsed[:path]).to eq("/pakyow-test")
    end

    it "parses the host" do
      expect(parsed[:host]).to eq("localhost")
    end

    it "parses the port" do
      expect(parsed[:port]).to eq(5432)
    end

    it "parses the user" do
      expect(parsed[:user]).to eq("test")
    end

    it "parses the password" do
      expect(parsed[:password]).to eq("testpw")
    end

    it "parses the query string" do
      expect(parsed[:timeout]).to eq("1")
    end
  end
end
