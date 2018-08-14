RSpec.describe "parsing json requests" do
  let :app do
    double
  end

  let :middleware do
    Pakyow::Middleware::JSONBody.new(app)
  end

  before do
    allow(app).to receive(:call)
  end

  context "when the request type is application/json" do
    context "and the request has a body" do
      let :body do
        { foo: "bar" }.to_json
      end

      let :env do
        {
          "CONTENT_TYPE" => "application/json",
          Rack::RACK_INPUT => StringIO.new(body)
        }
      end

      it "parses the json request body" do
        expect(JSON).to receive(:parse).with(body)
        middleware.call(env)
      end

      it "calls the app with the updated env, containing the parsed json" do
        expect(app).to receive(:call)
        middleware.call(env)

        expect(env[Rack::RACK_REQUEST_FORM_HASH]).to eq(JSON.parse(body))
      end
    end

    context "and the request does not have a body" do
      let :env do
        {}
      end

      it "calls the app with the original env" do
        expect(app).to receive(:call).with(env)
        middleware.call(env)
      end
    end
  end

  context "when the request type is not application/json" do
    let :env do
      {
        "CONTENT_TYPE" => "text/html"
      }
    end

    it "does not try to parse the request body" do
      expect(JSON).not_to receive(:parse)
      middleware.call(env)
    end

    it "calls the app with the original env" do
      expect(app).to receive(:call).with(env)
      middleware.call(env)
    end
  end
end
