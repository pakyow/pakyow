RSpec.describe "cookies" do
  include_context "app"

  let :app_def do
    Proc.new do
      configure do
        config.session.enabled = false
      end

      action do |connection|
        connection.body = StringIO.new(
          JSON.dump(connection.cookies)
        )

        connection.halt
      end
    end
  end

  it "exposes cookies passed in the request" do
    expect(JSON.load(call("/", headers: { "cookie" => "foo=bar; baz=qux" })[2])).to eq(
      { "foo" => "bar", "baz" => "qux" }
    )
  end

  context "no cookies are passed in the request" do
    it "is empty" do
      expect(JSON.load(call("/")[2]).keys).to be_empty
    end
  end

  describe "setting cookies" do
    let :app_def do
      Proc.new do
        configure do
          config.session.enabled = false
        end

        action do |connection|
          connection.cookies[:foo] = "bar"
          connection.cookies[:baz] = "qux"
          connection.halt
        end
      end
    end

    it "sets each cookie" do
      expect(call("/")[1]["set-cookie"].length).to eq(2)
      expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/")
      expect(call("/")[1]["set-cookie"][1]).to eq("baz=qux; path=/")
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
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies[:foo] = "bar"
          end
        end
      end

      it "sets cookies with defaults from the environment" do
        expect(call("/")[1]["set-cookie"].length).to eq(1)
        expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; domain=pakyow.com; path=/; expires=#{(Time.now + Pakyow.config.cookies.expires).httpdate}")
      end
    end

    describe "passing settings for a key" do
      let :app_def do
        Pakyow.configure do
          config.cookies.domain = "pakyow.com"
          config.cookies.max_age = 3600
        end

        Proc.new do
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies[:foo] = {
              value: "bar",
              path: "/foo",
              max_age: 42
            }
          end
        end
      end

      it "sets the cookie" do
        expect(call("/")[1]["set-cookie"][0]).to start_with("foo=bar")
      end

      it "uses the passed settings" do
        expect(call("/")[1]["set-cookie"][0]).to include("; path=/foo; ")
      end

      it "includes the default settings" do
        expect(call("/")[1]["set-cookie"][0]).to include("; domain=pakyow.com; ")
      end

      it "overrides the default settings" do
        expect(call("/")[1]["set-cookie"][0]).to include("; max-age=42")
      end

      describe "valid settings" do
        let :app_def do
          Proc.new do
            configure do
              config.session.enabled = false
            end

            action do |connection|
              connection.cookies[:foo] = {
                value: "bar",
                domain: "pakyow.com",
                path: "/foo",
                max_age: 42,
                expires: Time.now + 42,
                secure: true,
                http_only: true
              }
            end
          end
        end

        it "sets domain" do
          expect(call("/")[1]["set-cookie"][0]).to include("; domain=pakyow.com; ")
        end

        it "sets path" do
          expect(call("/")[1]["set-cookie"][0]).to include("; path=/foo; ")
        end

        it "sets max_age" do
          expect(call("/")[1]["set-cookie"][0]).to include("; max-age=42; ")
        end

        it "sets expires" do
          expect(call("/")[1]["set-cookie"][0]).to include("; expires=#{(Time.now + 42).httpdate}; ")
        end

        it "sets secure" do
          expect(call("/")[1]["set-cookie"][0]).to include("; Secure; ")
        end

        it "sets http_only" do
          expect(call("/")[1]["set-cookie"][0]).to include("; HttpOnly")
        end

        describe "same_site" do
          let :app_def do
            local = self

            Proc.new do
              configure do
                config.session.enabled = false
              end

              action do |connection|
                connection.cookies[:foo] = {
                  value: "bar",
                  same_site: local.same_site
                }
              end
            end
          end

          context "value is lax" do
            let :same_site do
              "lax"
            end

            it "is set" do
              expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/; SameSite=Lax")
            end
          end

          context "value is strict" do
            let :same_site do
              "strict"
            end

            it "is set" do
              expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/; SameSite=Strict")
            end
          end

          context "value is unsupported" do
            let :same_site do
              "foo"
            end

            it "is not set" do
              expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/")
            end
          end
        end
      end

      describe "setting an unsupported setting" do
        let :app_def do
          local = self

          Proc.new do
            configure do
              config.session.enabled = false
            end

            action do |connection|
              connection.cookies[:foo] = {
                value: "bar",
                foo: "bar"
              }
            end
          end
        end

        it "is ignored" do
          expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/")
        end
      end

      describe "setting is nil" do
        let :app_def do
          local = self

          Proc.new do
            configure do
              config.session.enabled = false
            end

            action do |connection|
              connection.cookies[:foo] = {
                value: "bar",
                foo: nil
              }
            end
          end
        end

        it "is ignored" do
          expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/")
        end
      end

      describe "setting is empty" do
        let :app_def do
          local = self

          Proc.new do
            configure do
              config.session.enabled = false
            end

            action do |connection|
              connection.cookies[:foo] = {
                value: "bar",
                foo: ""
              }
            end
          end
        end

        it "is ignored" do
          expect(call("/")[1]["set-cookie"][0]).to eq("foo=bar; path=/")
        end
      end
    end

    describe "escaping" do
      let :app_def do
        local = self

        Proc.new do
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies[:"foo$"] = {
              value: "  bar\n",
            }
          end
        end
      end

      it "escapes keys" do
        expect(call("/")[1]["set-cookie"][0]).to start_with("foo%24=")
      end

      it "escapes values" do
        expect(call("/")[1]["set-cookie"][0]).to end_with("=++bar%0A; path=/")
      end
    end
  end

  describe "changing cookies" do
    let :app_def do
      local = self

      Proc.new do
        configure do
          config.session.enabled = false
        end

        action do |connection|
          connection.cookies[:foo] = "bar"
        end
      end
    end

    it "sets the cookie" do
      expect(call("/", headers: { "cookie" => "foo=foo" })[1]["set-cookie"][0]).to eq("foo=bar; path=/")
    end

    context "cookie value does not change" do
      it "does not set the cookie" do
        expect(call("/", headers: { "cookie" => "foo=bar" })[1]["set-cookie"]).to be_nil
      end
    end
  end

  describe "deleting cookies" do
    context "key is removed" do
      let :app_def do
        local = self

        Proc.new do
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies.delete(:foo)
          end
        end
      end

      it "deletes the cookie" do
        expect(call("/", headers: { "cookie" => "foo=bar" })[1]["set-cookie"][0]).to eq("foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
      end
    end

    context "key is set to nil" do
      let :app_def do
        local = self

        Proc.new do
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies[:foo] = nil
          end
        end
      end

      it "deletes the cookie" do
        expect(call("/", headers: { "cookie" => "foo=bar" })[1]["set-cookie"][0]).to eq("foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
      end
    end

    context "key is set to empty" do
      let :app_def do
        local = self

        Proc.new do
          configure do
            config.session.enabled = false
          end

          action do |connection|
            connection.cookies[:foo] = ""
          end
        end
      end

      it "deletes the cookie" do
        expect(call("/", headers: { "cookie" => "foo=bar" })[1]["set-cookie"][0]).to eq("foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
      end
    end
  end
end
