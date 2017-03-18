RSpec.describe "using cookies" do
  include_context "testable app"

  describe "creating a cookie" do
    context "using the pakyow helper" do
      let :app_definition do
        -> {
          router do
            get "/set/:value" do
              cookies[:foo] = params[:value]
            end
          end
        }
      end

      it "creates the cookie" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).to include("foo=foo;")
      end

      it "uses the configured path" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).to include("path=#{Pakyow::App.config.cookies.path};")
      end

      it "uses the configured expiry" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expiry = Time.now + Pakyow::App.config.cookies.expiry
        expect(cookie).to include("expires=#{expiry.utc.rfc2822}")
      end
    end

    context "using request.set_cookie" do
      let :app_definition do
        -> {
          router do
            get "/set/:value" do
              response.set_cookie(
                :foo,
                path: "/path",
                value: params[:value],
                expires: Time.now + 1
              )
            end
          end
        }
      end

      it "creates the cookie with the provided value" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).to include("foo=foo;")
      end

      it "uses the provided path" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).to include("path=/path;")
      end

      it "uses the provided expiry" do
        cookie = call("/set/foo")[1].fetch("Set-Cookie").split("\n")[0]
        expiry = Time.now + 1
        expect(cookie).to include("expires=#{expiry.utc.rfc2822}")
      end
    end
  end

  describe "accessing a cookie" do
    let :cookie do
      "foo=bar"
    end

    context "using the pakyow helper" do
      let :app_definition do
        -> {
          router do
            get "/" do
              send cookies[:foo] || ""
            end
          end
        }
      end

      it "is accessible" do
        expect(call("/", "HTTP_COOKIE" => cookie)[2].body.read).to eq("bar")
      end
    end

    context "using request.cookies" do
      let :app_definition do
        -> {
          router do
            get "/" do
              send request.cookies[:foo] || ""
            end
          end
        }
      end

      it "is accessible" do
        expect(call("/", "HTTP_COOKIE" => cookie)[2].body.read).to eq("bar")
      end
    end
  end

  describe "deleting a cookie" do
    let :cookie do
      "foo=bar"
    end

    context "using the pakyow helper" do
      let :app_definition do
        -> {
          router do
            get "/" do
              cookies[:foo] = nil
            end
          end
        }
      end

      it "deletes the cookie" do
        res_cookie = call("/", "HTTP_COOKIE" => cookie)[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).not_to include(res_cookie)
      end
    end

    context "using request.delete_cookie" do
      let :app_definition do
        -> {
          router do
            get "/" do
              response.delete_cookie(:foo)
            end
          end
        }
      end

      it "deletes the cookie" do
        res_cookie = call("/", "HTTP_COOKIE" => cookie)[1].fetch("Set-Cookie").split("\n")[0]
        expect(cookie).not_to include(res_cookie)
      end
    end
  end
end
