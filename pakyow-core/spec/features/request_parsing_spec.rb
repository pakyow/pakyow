RSpec.describe "parsing requests" do
  include_context "app"

  let :app_init do
    Proc.new do
      after :initialize, priority: :low do
        @__pipeline.action Proc.new { |connection|
          connection.body = connection.params
          connection.halt
        }
      end
    end
  end

  context "content type is application/json" do
    it "parses the json request body" do
      result = call("/", input: { foo: "bar" }.to_json, "CONTENT_TYPE" => "application/json")
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq(foo: "bar")
    end

    context "parsing fails" do
      it "responds as a bad request" do
        result = call("/", input: "{;;;;", "CONTENT_TYPE" => "application/json")
        expect(result[0]).to eq(400)
      end
    end
  end
end
