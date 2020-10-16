RSpec.describe Pakyow::Types do
  describe ".type_for" do
    context "passed a known type" do
      it "returns the type class" do
        expect(Pakyow::Types.type_for(:string)).to be(Pakyow::Types::Coercible::String)
      end
    end

    context "passed an unknown type" do
      it "raises an UnknownType error" do
        expect { Pakyow::Types.type_for(:foo) }.to raise_error(Pakyow::UnknownType) do |error|
          expect(error.message).to eq("`foo' is not a known type")
        end
      end
    end

    context "passed a type class" do
      it "returns the type class" do
        expect(Pakyow::Types.type_for(Pakyow::Types::Coercible::String)).to be(Pakyow::Types::Coercible::String)
      end
    end
  end

  describe "known types" do
    describe "string" do
      it "is known" do
        expect(Pakyow::Types.type_for(:string)).to be(Pakyow::Types::Coercible::String)
      end
    end

    describe "boolean" do
      it "is known" do
        expect(Pakyow::Types.type_for(:boolean)).to be(Pakyow::Types::Params::Bool)
      end
    end

    describe "date" do
      it "is known" do
        expect(Pakyow::Types.type_for(:date)).to be(Pakyow::Types::Params::Date)
      end
    end

    describe "time" do
      it "is known" do
        expect(Pakyow::Types.type_for(:time)).to be(Pakyow::Types::Params::Time)
      end
    end

    describe "datetime" do
      it "is known" do
        expect(Pakyow::Types.type_for(:datetime)).to be(Pakyow::Types::Params::Time)
      end
    end

    describe "integer" do
      it "is known" do
        expect(Pakyow::Types.type_for(:integer)).to be(Pakyow::Types::Params::Integer)
      end
    end

    describe "float" do
      it "is known" do
        expect(Pakyow::Types.type_for(:float)).to be(Pakyow::Types::Params::Float)
      end
    end

    describe "decimal" do
      it "is known" do
        expect(Pakyow::Types.type_for(:decimal)).to be(Pakyow::Types::Params::Decimal)
      end
    end
  end
end
