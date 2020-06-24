require "smoke_helper"

RSpec.describe "sessions, with the cookie adapter", smoke: true do
  let(:set_response) {
    HTTP.put("http://localhost:#{port}/session/set")
  }

  let(:get_response) {
    HTTP.get("http://localhost:#{port}/session/get", headers: {
      "cookie" => "smoke_test.session=#{extract_session(set_response)}"
    })
  }

  def extract_session(response)
    response.headers["Set-Cookie"].split("smoke_test.session=", 2)[1].split(";", 2)[0]
  end

  describe "setting and getting a session" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            controller "/session" do
              disable_protection :csrf

              put "/set" do
                session[:foo] = :bar
              end

              get "/get" do
                send session[:foo].inspect
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "sets the session" do
      expect(set_response.headers["Set-Cookie"]).to start_with("smoke_test.session=")
      expect(set_response.headers["Set-Cookie"]).to end_with("; path=/; HttpOnly")
    end

    it "gets the session" do
      expect(get_response.body.to_s).to eq(":bar")
    end
  end

  describe "changing a session value" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            controller "/session" do
              disable_protection :csrf

              put "/set" do
                session[:foo] = :bar
              end

              put "/chg" do
                session[:bar] = :baz
              end

              get "/get" do
                send(
                  {
                    foo: session[:foo].inspect,
                    bar: session[:bar].inspect
                  }.inspect
                )
              end
            end
          end
        SOURCE
      end

      boot
    end

    let(:chg_response) {
      HTTP.put("http://localhost:#{port}/session/chg", headers: {
        "cookie" => "smoke_test.session=#{extract_session(set_response)}"
      })
    }

    let(:get_response_2) {
      HTTP.get("http://localhost:#{port}/session/get", headers: {
        "cookie" => "smoke_test.session=#{extract_session(chg_response)}"
      })
    }

    it "changes the value" do
      expect(get_response_2.body.to_s).to eq('{:foo=>":bar", :bar=>":baz"}')
    end
  end

  describe "deleting a session" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            controller "/session" do
              disable_protection :csrf

              put "/set" do
                session[:foo] = :bar
              end

              delete "/del" do
                session.delete(:foo)
              end

              get "/get" do
                send session[:foo].inspect
              end
            end
          end
        SOURCE
      end

      boot
    end

    let(:del_response) {
      HTTP.delete("http://localhost:#{port}/session/del", headers: {
        "cookie" => "smoke_test.session=#{extract_session(set_response)}"
      })
    }

    let(:get_response_2) {
      HTTP.get("http://localhost:#{port}/session/get", headers: {
        "cookie" => "smoke_test.session=#{extract_session(del_response)}"
      })
    }

    it "deletes the session" do
      expect(get_response_2.body.to_s).to eq("nil")
    end
  end

  describe "tampering with a session" do
    before do
      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            controller "/session" do
              disable_protection :csrf

              get "/get" do
                send session[:foo].inspect
              end
            end
          end
        SOURCE
      end

      boot
    end

    let(:get_response) {
      HTTP.get("http://localhost:#{port}/session/get", headers: {
        "cookie" => "hacked"
      })
    }

    it "gracefully resets the session" do
      expect(get_response.status).to eq(200)
      expect(get_response.body.to_s).to eq("nil")
    end
  end
end
