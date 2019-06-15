RSpec.describe "email validation" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_init do
    Proc.new do
      controller do
        verify :test do
          required :value do
            validate :unique, source: :posts
          end
        end

        get :test, "/test"
      end

      source :posts do
        attribute :value
      end
    end
  end

  before do
    Pakyow.apps.first.data.posts.create(value: "foo")
  end

  context "value is not accepted" do
    it "responds 400" do
      expect(call("/test", params: { value: "foo" })[0]).to eq(400)
    end
  end

  context "value is accepted" do
    it "responds 200" do
      expect(call("/test", params: { value: "bar" })[0]).to eq(200)
    end
  end
end
