RSpec.describe "defining a controller" do
  include_context "app"

  let :app_def do
    Proc.new {
      controller do
        default
      end
    }
  end

  it "defines the controller" do
    expect(call[0]).to eq(200)
  end

  context "when the controller is defined with a path" do
    let :app_def do
      Proc.new {
        controller "/foo" do
          default
        end
      }
    end

    it "defines the controller" do
      expect(call("/foo")[0]).to eq(200)
    end
  end

  context "when the controller is defined with a custom matcher" do
    let :app_def do
      Proc.new {
        klass = Class.new do
          def match(path)
            self
          end

          def named_captures
            {}
          end
        end

        controller klass.new do
          default
        end
      }
    end

    it "defines the controller" do
      expect(call("/")[0]).to eq(200)
    end
  end

  context "controller is defined with a name" do
    let :app_def do
      Proc.new {
        controller :foo do
          default do
            send(self.class.name); halt
          end
        end
      }
    end

    it "defines the controller" do
      expect(call("/")[2]).to eq("Test::Controllers::Foo")
    end

    context "controller was defined previously" do
      let :app_def do
        Proc.new {
          controller :foo do
            get "/foo" do
              send(self.class.name); halt
            end
          end

          controller :foo do
            get "/bar" do
              send(self.class.name); halt
            end
          end
        }
      end

      it "extends the original controller" do
        expect(call("/foo")[2]).to eq("Test::Controllers::Foo")
        expect(call("/bar")[2]).to eq("Test::Controllers::Foo")
      end
    end
  end
end
