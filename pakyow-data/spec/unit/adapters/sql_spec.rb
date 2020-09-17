require "pakyow/data/adapters/sql"

RSpec.describe Pakyow::Data::Adapters::Sql do
  describe "#initialize" do
    before do
      allow(Sequel).to receive(:connect).and_return(connection)
    end

    let :connection do
      double(:connection, extension: nil, pool: pool)
    end

    let :pool do
      double(:pool, :connection_validation_timeout= => nil)
    end

    describe "connection validator" do
      before do
        described_class.new({})
      end

      it "loads the extension" do
        expect(connection).to have_received(:extension).with(:connection_validator)
      end

      context "timeout value is passed" do
        before do
          described_class.new({timeout: 123})
        end

        it "configures the timeout" do
          expect(pool).to have_received(:connection_validation_timeout=).with(123)
        end
      end

      context "timeout value is passed as a string" do
        before do
          described_class.new({timeout: "123"})
        end

        it "configures the timeout as an integer" do
          expect(pool).to have_received(:connection_validation_timeout=).with(123)
        end
      end

      context "timeout value is not passed" do
        before do
          described_class.new({})
        end

        it "does not configure the timeout" do
          expect(pool).to_not have_received(:connection_validation_timeout=)
        end
      end
    end
  end
end
