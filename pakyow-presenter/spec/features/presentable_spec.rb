RSpec.describe "presentable definitions" do
  include_context "testable app"

  module Pakyow::Helpers
    def global_method
      "global_method"
    end
  end

  let :app_definition do
    Proc.new {
      router :presentables do
        presentable :global_method
        presentable :global_value, "global_value"

        presentable :global_block do
          "global_block"
        end

        presentable :global_fallback, @default do
          "global_fallback"
        end

        get "global/:type" do
          @default = params[:default]
        end

        def local_method
          "local_method"
        end

        get "local/:type" do
          presentable :local_method
          presentable :local_value, "local_value"

          presentable :local_block do
            "local_block"
          end

          presentable :local_fallback, @default do
            "local_fallback"
          end

          @default = params[:default]
        end

        get "other/:type"
      end

      Pakyow::App.view "global/method" do
        view.html = global_method
      end

      Pakyow::App.view "global/value" do
        view.html = global_value
      end

      Pakyow::App.view "global/block" do
        view.html = global_block
      end

      Pakyow::App.view "global/fallback" do
        view.html = global_fallback
      end

      Pakyow::App.view "local/method" do
        view.html = local_method
      end

      Pakyow::App.view "local/value" do
        view.html = local_value
      end

      Pakyow::App.view "local/block" do
        view.html = local_block
      end

      Pakyow::App.view "local/fallback" do
        view.html = local_fallback
      end

      Pakyow::App.view "other/method" do
        view.html = local_method
      end

      Pakyow::App.view "other/value" do
        view.html = local_value
      end

      Pakyow::App.view "other/block" do
        view.html = instance_block
      end

      Pakyow::App.view "other/fallback" do
        view.html = instance_fallback
      end
    }
  end

  context "when a route is called" do
    it "can call global 'method' presentables" do
      expect(call("/global/method")[2].body.read).to eq("global_method")
    end

    it "can call global 'value' presentables" do
      expect(call("/global/value")[2].body.read).to eq("global_value")
    end

    it "can call global 'block' presentables" do
      expect(call("/global/block")[2].body.read).to eq("global_block")
    end

    it "can call global 'fallback' presentables (using default value)" do
      expect(call("/global/fallback?default=global_default")[2].body.read).to eq("global_default")
    end

    it "can call global 'fallback' presentables (using fallback value)" do
      expect(call("/global/fallback")[2].body.read).to eq("global_fallback")
    end
  end

  context "when a route with local presentables is called" do
    # TODO: call "local" routes and ensure they can call "local" presentables
  end

  context "when a route without local presentables is called" do
    # TODO: call "other" routes and ensure they cannot call "local" presentables
  end
end
