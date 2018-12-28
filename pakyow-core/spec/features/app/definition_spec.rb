require "pakyow/routing"

RSpec.describe "defining an app" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.name = "define-test"
    end
  end

  let :app_init do
    Proc.new do
      controller do
        default do
          send config.name
        end
      end
    end
  end

  it "defines the app" do
    res = call
    expect(res[0]).to eq(200)
    expect(res[2].body.read).to eq("define-test")
  end

  context "when app is a subclass" do
    let :base do
      klass = Class.new(Pakyow::App) do
        include_frameworks(:routing)
      end

      klass.define do
        config.name = "define-test"

        controller do
          default do
            send config.name
          end
        end
      end

      klass
    end

    let :app do
      Class.new(base).tap do |app|
        app.define(&app_def)
      end
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
      let :app_def do
        Proc.new do
          config.name = "child-test"
        end
      end

      it "uses the child's defined state" do
        res = call
        expect(res[0]).to eq(200)
        expect(res[2].body.read).to eq("child-test")
      end

      it "does not modify the parent state" do
        expect(base.config.name).to eq("define-test")
      end
    end
  end

  context "when app is extended at runtime" do
    let :app_init do
      Proc.new do
        config.name = "runtime-test"

        controller do
          default do
            send config.name
          end
        end
      end
    end

    it "is extended with the new state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("runtime-test")
    end

    it "does not modify the class-level state" do
      expect(app.config.name).to eq("define-test")
    end
  end
end
