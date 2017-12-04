RSpec.describe "defining an app" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      config.app.name = "define-test"

      controller do
        default do
          send config.app.name
        end
      end
    }
  end

  it "defines the app" do
    res = call
    expect(res[0]).to eq(200)
    expect(res[2].body.read).to eq("define-test")
  end

  context "when app is a subclass" do
    let :app_definition do
      Proc.new {}
    end

    let :base do
      klass = Class.new(Pakyow::App) do
        include_frameworks(:routing)
      end

      klass.define do
        config.app.name = "define-test"

        controller do
          default do
            send config.app.name
          end
        end
      end

      klass
    end

    let :app do
      app = Class.new(base)
      app.define(&app_definition)
      app
    end

    before do
      run
    end

    it "inherits parent state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("define-test")
    end

    context "and the subclassed app defines new state" do
      let :app_definition do
        Proc.new {
          config.app.name = "child-test"
        }
      end

      it "uses the child's defined state" do
        res = call
        expect(res[0]).to eq(200)
        expect(res[2].body.read).to eq("child-test")
      end

      it "does not modify the parent state" do
        expect(base.config.app.name).to eq("define-test")
      end
    end
  end

  context "when app is extended at runtime" do
    let :app_runtime_block do
      Proc.new {
        config.app.name = "runtime-test"
      }
    end

    it "is extended with the new state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("runtime-test")
    end

    it "does not modify the class-level state" do
      expect(app.config.app.name).to eq("define-test")
    end
  end
end
