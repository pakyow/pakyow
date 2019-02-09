RSpec.describe "cookies" do
  include_context "app"

  let :app_def do
    Proc.new do
      action do |connection|
        connection.body = StringIO.new(
          JSON.dump(connection.cookies)
        )

        connection.halt
      end
    end
  end

  it "exposes cookies passed in the request" do
    expect(JSON.load(call("/", headers: { "cookie" => "foo=bar; baz=qux" })[2])).to include(
      { "foo" => "bar", "baz" => "qux" }
    )
  end

  context "no cookies are passed in the request" do
    it "is empty" do
      expect(JSON.load(call("/")[2]).keys).to eq(["test.session"])
    end
  end

  describe "setting cookies" do
    let :app_def do
      Proc.new do
        action do |connection|
          connection.cookies[:foo] = "bar"
          connection.cookies[:baz] = "qux"
          connection.halt
        end
      end
    end

    it "sets each cookie" do
      expect(call("/")[1]["set-cookie"].length).to eq(3)
      expect(call("/")[1]["set-cookie"][0]).to include("test.session=")
      expect(call("/")[1]["set-cookie"][1]).to include("foo=bar")
      expect(call("/")[1]["set-cookie"][2]).to include("baz=qux")
    end

    describe "using default cookie settings" do
      before do
        Pakyow.config.cookies.expires = 3600 * 24
      end

      let :app_def do
        Pakyow.configure do
          config.cookies.domain = "pakyow.com"
          config.cookies.expires = 3600
        end

        Proc.new do
          action do |connection|
            connection.cookies[:foo] = "bar"
          end
        end
      end

      it "sets cookies with defaults from the environment" do
        expect(call("/")[1]["set-cookie"].length).to eq(2)
        expect(call("/")[1]["set-cookie"][0]).to include("test.session=")
        expect(call("/")[1]["set-cookie"][1]).to include("foo=bar")
      end

      it "sets cookies with defaults from the app"
      it "overrides the environment defaults with app defaults"
    end

    describe "passing settings for a key" do
      it "uses the passed settings"
      it "includes the default settings"
      it "overrides the default settings"

      describe "valid settings" do
        # domain, path, max_age, expires, secure, http_only, same_site
        it "needs tests"
      end

      describe "setting an unsupported setting" do
        it "is ignored"
      end
    end

    describe "escaping the value" do
      it "escapes keys"
      it "escapes values"
    end
  end

  describe "changing cookies" do
    it "sets the cookie"

    context "cookie value does not change" do
      it "does not set the cookie"
    end
  end

  describe "deleting cookies" do
    context "key is removed" do
      it "deletes the cookie"
    end

    context "key is set to nil" do
      it "deletes the cookie"
    end

    context "key is set to empty" do
      it "deletes the cookie"
    end
  end
end
