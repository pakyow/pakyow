RSpec.describe "using cookies" do
  before do
    Pakyow.config.cookies.path = "/"
    Pakyow.config.cookies.expires = 7
  end

  include_context "app"

  describe "creating a cookie" do
    context "using the pakyow helper" do
      let :app_def do
        Proc.new {
          controller do
            get "/set/:value" do
              cookies[:foo] = params[:value]
            end
          end
        }
      end

      it "creates the cookie" do
        cookie = call("/set/foo")[1].fetch("set-cookie")[1]
        expect(cookie).to include("foo=foo;")
      end

      it "uses the configured path" do
        cookie = call("/set/foo")[1].fetch("set-cookie")[1]
        expect(cookie).to include("path=#{Pakyow.config.cookies.path};")
      end

      it "uses the configured expires" do
        cookie = call("/set/foo")[1].fetch("set-cookie")[1]
        expires = Time.now + Pakyow.config.cookies.expires
        expect(cookie).to include("expires=#{expires.utc.httpdate}")
      end
    end
  end

  describe "accessing a cookie" do
    let :cookie do
      "foo=bar"
    end

    context "using the pakyow helper" do
      let :app_def do
        Proc.new {
          controller do
            get "/" do
              send cookies[:foo] || ""
            end
          end
        }
      end

      it "is accessible" do
        expect(call("/", headers: { "cookie" => cookie })[2]).to eq("bar")
      end
    end

    context "using request.cookies" do
      let :app_def do
        Proc.new {
          controller do
            get "/" do
              send cookies[:foo] || ""
            end
          end
        }
      end

      it "is accessible" do
        expect(call("/", headers: { "cookie" => cookie })[2]).to eq("bar")
      end
    end
  end

  describe "deleting a cookie" do
    let :cookie do
      "foo=bar"
    end

    context "using the pakyow helper" do
      let :app_def do
        Proc.new {
          controller do
            get "/" do
              cookies.delete(:foo)
            end
          end
        }
      end

      it "deletes the cookie" do
        res_cookie = call("/", headers: { "cookie" => cookie })[1].fetch("set-cookie")[0]
        expect(cookie).not_to include(res_cookie)
      end
    end

    context "using response.delete_cookie" do
      let :app_def do
        Proc.new {
          controller do
            get "/" do
              connection.cookies.delete(:foo)
            end
          end
        }
      end

      it "deletes the cookie" do
        res_cookie = call("/", headers: { "cookie" => cookie })[1].fetch("set-cookie")[0]
        expect(cookie).not_to include(res_cookie)
      end
    end
  end

  describe "setting a cookie to nil" do
    let :cookie do
      "foo=bar"
    end

    let :app_def do
      Proc.new {
        controller do
          get "/" do
            cookies[:foo] = nil
          end
        end
      }
    end

    it "deletes the cookie" do
      res_cookie = call("/", headers: { "cookie" => cookie })[1].fetch("set-cookie")[0]
      expect(cookie).not_to include(res_cookie)
    end
  end
end
