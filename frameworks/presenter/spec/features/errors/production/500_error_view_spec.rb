RSpec.describe "500 error views in production" do
  include_context "app"

  let :app_def do
    Proc.new do
      controller do
        get "/fail" do
          fail
        end
      end
    end
  end

  let :mode do
    :production
  end

  let :allow_request_failures do
    true
  end

  it "renders the built-in 500 page by default" do
    expect(call("/fail")[0]).to eq(500)
    expect(call("/fail")[2]).to include("500 (Server Error)")
  end

  context "app defines its own 500 page" do
    let :app_def do
      Proc.new do
        configure do
          config.presenter.path = File.expand_path("../../views", __FILE__)
        end

        controller do
          get "/fail" do
            fail
          end
        end
      end
    end

    it "renders the app's 500 page instead of the default" do
      expect(call("/fail")[0]).to eq(500)
      expect(call("/fail")[2]).to include("app 500")
    end
  end

  context "app defines its own 500 handler" do
    let :app_def do
      Proc.new do
        handle 500 do |connection:|
          connection.body = StringIO.new("foo")
          connection.halt
        end

        controller do
          get "/fail" do
            fail
          end
        end
      end
    end

    it "handles instead of presenter" do
      expect(call("/fail")[2]).to eq("foo")
    end

    context "handler renders the default 500 view" do
      let :app_def do
        Proc.new do
          handle 500 do |connection:|
            connection.render "/500"
          end

          controller do
            get "/fail" do
              fail
            end
          end
        end
      end

      it "renders" do
        expect(call("/fail")[0]).to eq(500)
        expect(call("/fail")[2]).to include("500 (Server Error)")
      end
    end

    context "handler renders a different view" do
      let :app_def do
        Proc.new do
          configure do
            config.presenter.path = File.expand_path("../../views", __FILE__)
          end

          handle 500 do |connection:|
            connection.render "/non_standard_500"
          end

          controller do
            get "/fail" do
              fail
            end
          end
        end
      end

      it "renders" do
        expect(call("/fail")[0]).to eq(500)
        expect(call("/fail")[2]).to include("non standard 500")
      end
    end
  end
end
