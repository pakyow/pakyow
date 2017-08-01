RSpec.describe "presentable definitions" do
  include_context "testable app"

  module Pakyow::Helpers
    def global_method
      "global_method"
    end
  end

  let :app_definition do
    Proc.new {
      include Pakyow::Presenter

      configure do
        config.presenter.path = "./spec/views"
      end

      router :default do
        presentable :global_method
        presentable :global_value, "global_value"

        presentable :global_block do
          "global_block"
        end

        presentable :global_default, "global_default" do
          "global_fallback"
        end

        presentable :global_fallback, nil do
          "global_fallback"
        end

        get "global/:type" do
          render "global/#{params[:type]}"
        end

        get "local/:type" do
          def local_method
            "local_method"
          end

          presentable :local_method
          presentable :local_value, "local_value"

          presentable :local_block do
            "local_block"
          end

          presentable :local_default, "local_default" do
            "local_fallback"
          end

          presentable :local_fallback, nil do
            "local_fallback"
          end

          render "local/#{params[:type]}"
        end

        get "other/:type" do
          render "other/#{params[:type]}"
        end
      end

      Pakyow::App.view "global/method" do
        view.replace(global_method)
      end

      Pakyow::App.view "global/value" do
        view.replace(global_value)
      end

      Pakyow::App.view "global/block" do
        view.replace(global_block)
      end

      Pakyow::App.view "global/default" do
        view.replace(global_default)
      end

      Pakyow::App.view "global/fallback" do
        view.replace(global_fallback)
      end

      Pakyow::App.view "local/method" do
        view.replace(local_method)
      end

      Pakyow::App.view "local/value" do
        view.replace(local_value)
      end

      Pakyow::App.view "local/block" do
        view.replace(local_block)
      end

      Pakyow::App.view "local/default" do
        view.replace(local_default)
      end

      Pakyow::App.view "local/fallback" do
        view.replace(local_fallback)
      end

      Pakyow::App.view "other/method" do
        view.replace(self.respond_to?('local_method').to_s)
      end

      Pakyow::App.view "other/value" do
        view.replace(self.respond_to?('local_value').to_s)
      end

      Pakyow::App.view "other/block" do
        view.replace(self.respond_to?('local_block').to_s)
      end

      Pakyow::App.view "other/default" do
        view.replace(self.respond_to?('local_default').to_s)
      end

      Pakyow::App.view "other/fallback" do
        view.replace(self.respond_to?('local_fallback').to_s)
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
      expect(call("/global/default")[2].body.read).to eq("global_default")
    end

    it "can call global 'fallback' presentables (using fallback value)" do
      expect(call("/global/fallback")[2].body.read).to eq("global_fallback")
    end
  end

  context "when a route with local presentables is called" do
    it "can call local 'method' presentables" do
      expect(call("/local/method")[2].body.read).to eq("local_method")
    end

    it "can call local 'value' presentables" do
      expect(call("/local/value")[2].body.read).to eq("local_value")
    end

    it "can call local 'block' presentables" do
      expect(call("/local/block")[2].body.read).to eq("local_block")
    end

    it "can call local 'fallback' presentables (using default value)" do
      expect(call("/local/default")[2].body.read).to eq("local_default")
    end

    it "can call local 'fallback' presentables (using fallback value)" do
      expect(call("/local/fallback")[2].body.read).to eq("local_fallback")
    end
  end

  context "when a route without local presentables is called" do
    it "cannot call 'method' presentables defined in different route" do
      expect(call("/other/method")[2].body.read).to eq("false")
    end

    it "cannot call 'value' presentables defined in different route" do
      expect(call("/other/value")[2].body.read).to eq("false")
    end

    it "cannot call 'block' presentables defined in different route" do
      expect(call("/other/block")[2].body.read).to eq("false")
    end

    it "cannot call 'default' presentables defined in different route" do
      expect(call("/other/default")[2].body.read).to eq("false")
    end

    it "cannot call 'fallback' presentables defined in different route" do
      expect(call("/other/fallback")[2].body.read).to eq("false")
    end
  end
end
