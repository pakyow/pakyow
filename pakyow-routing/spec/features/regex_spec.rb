RSpec.describe "routing with regex matchers" do
  include_context "app"

  context "when route is defined with a regex" do
    let :app_init do
      Proc.new {
        controller do
          get(/.*/) do
            send "regex"
          end
        end
      }
    end

    it "still matches the route" do
      expect(call("/foo")[2].read).to eq("regex")
    end

    context "when regex contains named captures" do
      let :app_init do
        Proc.new {
          controller do
            get(/\/(?<input>.*)/) do
              send params[:input] || ""
            end
          end
        }
      end

      it "makes the captures available as params" do
        expect(call("/foo")[2].read).to eq("foo")
      end
    end
  end

  context "when a namespace is defined with a regex" do
    let :app_init do
      Proc.new {
        controller do
          namespace(/foo/) do
            default do
              send "foo"
            end
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[2].first).to eq("foo")
    end
  end

  context "when a controller is defined with a regex" do
    let :app_init do
      Proc.new {
        controller(/foo/) do
          default do
            send "foo"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[2].first).to eq("foo")
    end
  end
end
