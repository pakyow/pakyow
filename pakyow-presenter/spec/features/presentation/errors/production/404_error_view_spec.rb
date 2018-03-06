RSpec.describe "404 error views in production" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)
    }
  end

  let :mode do
    :production
  end

  it "renders the built-in 404 page by default" do
    expect(call("/missing")[0]).to eq(404)
    expect(call("/missing")[2].body.read).to include("404 (Not Found)")
  end

  context "app defines its own 404 page" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        configure do
          config.presenter.path = File.expand_path("../../views", __FILE__)
        end
      }
    end

    it "renders the app's 404 page instead of the default" do
      expect(call("/missing")[0]).to eq(404)
      expect(call("/missing")[2].body.read).to include("app 404")
    end
  end

  context "app defines its own 404 handler" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        handle 404 do
          $handled = true
          res.body << "foo"
        end
      }
    end

    after do
      $handled = false
    end

    it "handles instead of presenter" do
      expect(call("/missing")[2].body).to eq(["foo"])
      expect($handled).to eq(true)
    end

    context "handler renders the default 404 view" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          handle 404 do
            render "/404"
          end
        }
      end

      it "renders" do
        expect(call("/missing")[0]).to eq(404)
        expect(call("/missing")[2].body.read).to include("404 (Not Found)")
      end
    end

    context "handler renders a different view" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          configure do
            config.presenter.path = File.expand_path("../../views", __FILE__)
          end

          handle 404 do
            render "/non_standard_404"
          end
        }
      end

      it "renders" do
        expect(call("/missing")[0]).to eq(404)
        expect(call("/missing")[2].body.read).to include("non standard 404")
      end
    end
  end
end
