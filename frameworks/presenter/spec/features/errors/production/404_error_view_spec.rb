RSpec.describe "404 error views in production" do
  include_context "app"

  let :mode do
    :production
  end

  let :allow_request_failures do
    true
  end

  it "renders the built-in 404 page by default" do
    expect(call("/missing")[0]).to eq(404)
    expect(call("/missing")[2]).to include("404 (Not Found)")
  end

  it "does not report to houston" do
    expect(Pakyow).not_to receive(:houston)

    call("/missing")
  end

  context "app defines its own 404 page" do
    let :app_def do
      Proc.new do
        configure do
          config.presenter.path = File.expand_path("../../views", __FILE__)
        end
      end
    end

    it "renders the app's 404 page instead of the default" do
      expect(call("/missing")[0]).to eq(404)
      expect(call("/missing")[2]).to include("app 404")
    end
  end

  context "app defines its own 404 handler" do
    let :app_def do
      Proc.new do
        handle 404 do |connection:|
          connection.body = StringIO.new("foo")
          connection.halt
        end
      end
    end

    it "handles instead of presenter" do
      expect(call("/missing")[2]).to eq("foo")
    end

    context "handler renders the default 404 view" do
      let :app_def do
        Proc.new do
          handle 404 do |connection:|
            connection.render "/404"
          end
        end
      end

      it "renders" do
        expect(call("/missing")[0]).to eq(404)
        expect(call("/missing")[2]).to include("404 (Not Found)")
      end
    end

    context "handler renders a different view" do
      let :app_def do
        Proc.new do
          configure do
            config.presenter.path = File.expand_path("../../views", __FILE__)
          end

          handle 404 do |connection:|
            connection.render "/non_standard_404"
          end
        end
      end

      it "renders" do
        expect(call("/missing")[0]).to eq(404)
        expect(call("/missing")[2]).to include("non standard 404")
      end
    end
  end
end
