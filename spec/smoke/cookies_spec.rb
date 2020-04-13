require "smoke_helper"

RSpec.describe "cookies", smoke: true do
  describe "setting and getting a cookie" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            configure do
              config.session.enabled = false
            end

            controller "/cookies" do
              disable_protection :csrf

              put "/set" do
                cookies[:foo] = "bar"
              end

              get "/get" do
                send cookies[:foo]
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "sets the cookie with default options" do
      response = HTTP.put("http://localhost:#{port}/cookies/set")
      expect(response.headers["Set-Cookie"]).to eq("foo=bar; path=/")
    end

    it "gets the cookie" do
      response = HTTP.get("http://localhost:#{port}/cookies/get", headers: { "cookie" => "foo=bar" })
      expect(response.body.to_s).to eq("bar")
    end
  end

  describe "setting a cookie with options" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            configure do
              config.session.enabled = false
            end

            controller "/cookies" do
              disable_protection :csrf

              put "/set" do
                cookies[:foo] = {
                  value: "bar",
                  domain: "pakyow.com",
                  path: "/",
                  max_age: 60,
                  expires: Time.now + 120,
                  secure: true,
                  http_only: true,
                  same_site: "strict"
                }
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "sets the cookie" do
      response = HTTP.put("http://localhost:#{port}/cookies/set")
      expect(response.headers["Set-Cookie"]).to eq("foo=bar; domain=pakyow.com; path=/; max-age=60; expires=#{(Time.now + 120).httpdate}; Secure; HttpOnly; SameSite=Strict")
    end
  end

  describe "setting and getting multiple cookies" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            configure do
              config.session.enabled = false
            end

            controller "/cookies" do
              disable_protection :csrf

              put "/set" do
                cookies[:foo] = "bar"
                cookies[:bar] = "baz"
              end

              get "/get" do
                send cookies[:foo] + cookies[:bar]
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "sets each cookie" do
      response = HTTP.put("http://localhost:#{port}/cookies/set")
      expect(response.headers["Set-Cookie"][0]).to eq("foo=bar; path=/")
      expect(response.headers["Set-Cookie"][1]).to eq("bar=baz; path=/")
    end

    it "gets each cookie" do
      response = HTTP.get("http://localhost:#{port}/cookies/get", headers: { "cookie" => "foo=bar; bar=baz" })
      expect(response.body.to_s).to eq("barbaz")
    end
  end

  describe "changing the value of a cookie" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            configure do
              config.session.enabled = false
            end

            controller "/cookies" do
              disable_protection :csrf

              put "/chg" do
                cookies[:foo] = "bar"
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "changes the value" do
      response = HTTP.put("http://localhost:#{port}/cookies/chg", headers: { "cookie" => "foo=foo" })
      expect(response.headers["Set-Cookie"]).to eq("foo=bar; path=/")
    end
  end

  describe "deleting cookies" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            configure do
              config.session.enabled = false
            end

            controller "/cookies" do
              disable_protection :csrf

              delete "/del" do
                cookies[:foo] = nil
                cookies.delete(:bar)
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "deletes cookies set to nil" do
      response = HTTP.delete("http://localhost:#{port}/cookies/del", headers: { "cookie" => "foo=foo" })
      expect(response.headers["Set-Cookie"]).to eq("foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
    end

    it "deletes cookies deleted on the server" do
      response = HTTP.delete("http://localhost:#{port}/cookies/del", headers: { "cookie" => "bar=bar" })
      expect(response.headers["Set-Cookie"]).to eq("bar=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
    end
  end
end
