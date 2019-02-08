RSpec.describe "routing with custom matchers" do
  include_context "app"

  context "when route is defined with a custom matcher" do
    let :app_init do
      Proc.new {
        matcher = Class.new do
          def match(path)
            self if path == "/custom"
          end

          def named_captures
            {}
          end
        end

        controller do
          get matcher.new do
            send "custom"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/custom")[0]).to eq(200)
      expect(call("/custom")[2].first).to eq("custom")
    end

    it "is not matched" do
      expect(call("/foo")[0]).to eq(404)
    end

    context "and the custom matcher provides a match" do
      let :app_init do
        Proc.new {
          matcher = Class.new do
            def match(path)
              self
            end

            def named_captures
              { "foo" => "bar" }
            end
          end

          controller do
            get matcher.new do
              send params[:foo] || ""
            end
          end
        }
      end

      it "makes the match's named captures available as params" do
        expect(call("/anything")[2].first).to eq("bar")
      end
    end
  end

  context "when route is defined with a custom matcher within a namespace" do
    let :app_init do
      Proc.new {
        matcher = Class.new do
          def match(path)
            self if path == "/custom"
          end

          def named_captures
            {}
          end
        end

        controller "/ns" do
          get matcher.new do
            send "custom"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/ns/custom")[2].first).to eq("custom")
    end

    it "is not matched" do
      expect(call("/foo")[0]).to eq(404)
    end
  end

  context "when route is defined with a custom matcher within a parameterized namespace" do
    let :app_init do
      Proc.new {
        matcher = Class.new do
          def match(path)
            self if path == "/"
          end

          def named_captures
            {}
          end
        end

        controller "/:id" do
          get matcher.new do
            send params[:id] || ""
          end
        end
      }
    end

    it "is matched" do
      expect(call("/123")[0]).to eq(200)
      expect(call("/123")[2].first).to eq("123")
    end

    it "is not matched" do
      expect(call("/123/foo")[0]).to eq(404)
    end
  end

  context "when a controller is defined with a custom matcher" do
    let :app_init do
      Proc.new {
        matcher = Class.new do
          def match(path)
            self
          end

          def named_captures
            {}
          end
        end

        controller matcher.new do
          get "/foo" do
            send "foo"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2].first).to eq("foo")
    end
  end

  context "when a namespace is defined with a custom matcher" do
    let :app_init do
      Proc.new {
        matcher = Class.new do
          def match(path)
            self
          end

          def named_captures
            {}
          end
        end

        controller do
          namespace matcher.new do
            get "/foo" do
              send "foo"
            end
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2].first).to eq("foo")
    end
  end
end
