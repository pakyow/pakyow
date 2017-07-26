RSpec.describe "router priority" do
  include_context "testable app"

  context "when no priority is set" do
    let :app_definition do
      Proc.new {
        router do
          default do
            send "one"
          end
        end

        router do
          default do
            send "two"
          end
        end
      }
    end

    it "prioritizes routers as first in, first out" do
      expect(call[2].body.first).to eq("one")
    end
  end

  context "when a router is defined as high priority" do
    let :app_definition do
      Proc.new {
        router do
          default do
            send "one"
          end
        end

        router priority: :high do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized above the others" do
      expect(call[2].body.first).to eq("two")
    end
  end

  context "when a router is defined as low priority" do
    let :app_definition do
      Proc.new {
        router priority: :low do
          default do
            send "one"
          end
        end

        router do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized below the others" do
      expect(call[2].body.first).to eq("two")
    end
  end

  context "when a router is defined with a custom priority" do
    let :app_definition do
      Proc.new {
        router priority: :high do
          default do
            send "one"
          end
        end

        router priority: 100 do
          default do
            send "two"
          end
        end
      }
    end

    it "is prioritized related to the others" do
      expect(call[2].body.first).to eq("two")
    end
  end
end
