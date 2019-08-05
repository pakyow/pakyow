RSpec.describe "dataset parsing" do
  let :dataset do
    Pakyow::Reflection::Exposure.new(
      scope: nil, nodes: [], binding: nil, dataset: string
    ).dataset
  end

  context "query" do
    let :string do
      "query: foo"
    end

    it "parses" do
      expect(dataset).to eq(query: "foo")
    end
  end

  context "limit" do
    let :string do
      "limit: 42"
    end

    it "parses" do
      expect(dataset).to eq(limit: "42")
    end
  end

  context "order" do
    let :string do
      "order: id"
    end

    it "parses" do
      expect(dataset).to eq(order: "id")
    end
  end

  context "multiple orders" do
    let :string do
      "order: id, name"
    end

    it "parses" do
      expect(dataset).to eq(order: ["id", "name"])
    end
  end

  context "order with direction" do
    let :string do
      "order: id(desc)"
    end

    it "parses" do
      expect(dataset).to eq(order: [["id", "desc"]])
    end
  end

  context "complex ordering" do
    let :string do
      "order: id(desc), name(asc), foo"
    end

    it "parses" do
      expect(dataset).to eq(order: [["id", "desc"], ["name", "asc"], "foo"])
    end
  end

  context "multiple parts" do
    let :string do
      "query: all; order: id(desc); limit: 42"
    end

    it "parses" do
      expect(dataset).to eq(query: "all", order: [["id", "desc"]], limit: "42")
    end
  end
end
