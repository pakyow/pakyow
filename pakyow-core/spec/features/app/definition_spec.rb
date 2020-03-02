RSpec.describe "defining an app" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.name = "define-test"

      action do |connection|
        connection.body = StringIO.new(config.name)
        connection.halt
      end
    end
  end

  it "defines the app" do
    res = call
    expect(res[0]).to eq(200)
    expect(res[2]).to eq("define-test")
  end

  context "when app is a subclass" do
    let :base do
      klass = Pakyow::Application.make(:base)

      klass.define do
        config.name = "define-test"

        action do |connection|
          connection.body = StringIO.new(config.name)
          connection.halt
        end
      end

      klass
    end

    let :app do
      base.make(:test).tap do |app|
        app.define(&app_def)
      end
    end

    it "inherits parent state" do
      res = call
      expect(res[0]).to eq(200)
      expect(res[2]).to eq("define-test")
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
        expect(res[2]).to eq("child-test")
      end

      it "does not modify the parent state" do
        expect(base.config.name).to eq("define-test")
      end
    end
  end

  describe "defining the same app twice" do
    let :app_def do
      Proc.new do
        config.name = "define-test"

        action do |connection|
          connection.body = StringIO.new(config.name.to_s)
          connection.halt
        end

        Pakyow.app :test do
          config.name = "define-test2"
        end
      end
    end

    it "extends the second time" do
      expect(call[2]).to eq("define-test2")
    end

    context "second definition has a different mount point" do
      let :app_def do
        Proc.new do
          config.name = "define-test"

          action do |connection|
            connection.body = StringIO.new(config.name.to_s)
            connection.halt
          end

          Pakyow.app :test, path: "/other" do
          end
        end
      end

      it "changes the mount point" do
        expect(call("/")[0]).to eq(404)
        expect(call("/other")[2]).to eq("define-test")
      end
    end
  end
end
