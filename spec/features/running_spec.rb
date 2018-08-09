RSpec.describe "running the environment" do
  before do
    Pakyow.config.server.name = :mock
  end

  context "with no mounted endpoints" do
    it "raises a runtime error" do
      expect {
        Pakyow.setup(env: :test).run
      }.to raise_error(RuntimeError)
    end
  end

  context "with a mounted rack endpoint" do
    before do
      klass = Class.new do
        def call(env)
          [200, {}, "foo"]
        end
      end

      Pakyow.mount klass, at: "/"
      Pakyow.setup(env: :test).run
    end

    it "runs the endpoint" do
      res = Pakyow.builder.call(Rack::MockRequest.env_for("/"))
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("foo")
    end
  end
end
