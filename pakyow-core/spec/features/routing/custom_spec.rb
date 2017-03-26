RSpec.describe "routing with custom matchers" do
  include_context "testable app"

  context "when route is defined with a custom matcher" do
    class CustomMatcher
      def match?(path)
        path == "/custom"
      end
    end

    let :app_definition do
      -> {
        router do
          get CustomMatcher.new do
            send "custom"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/custom")[0]).to eq(200)
      expect(call("/custom")[2].body.first).to eq("custom")
    end

    it "is not matched" do
      expect(call("/foo")[0]).to eq(404)
    end

    context "and the custom matcher provides a match" do
      class CustomMatcherWithMatch
        def match?(path)
          true
        end

        def match(path)
          self
        end

        def named_captures
          { "foo" => "bar" }
        end
      end

      let :app_definition do
        -> {
          router do
            get CustomMatcherWithMatch.new do
              send params[:foo] || ""
            end
          end
        }
      end

      it "makes the match's named captures available as params" do
        expect(call("/anything")[2].body.first).to eq("bar")
      end
    end
  end

  context "when route is defined with a custom matcher within a namespace" do
    class NestedCustomMatcher
      def match?(path)
        path == "/custom"
      end
    end

    let :app_definition do
      -> {
        router "/ns" do
          get NestedCustomMatcher.new do
            send "custom"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/ns/custom")[2].body.first).to eq("custom")
    end

    it "is not matched" do
      expect(call("/foo")[2].body.first).to eq(nil)
    end
  end

  context "when route is defined with a custom matcher within a parameterized namespace" do
    class ParameterizedCustomMatcher
      def match?(path)
        path == "/"
      end
    end

    let :app_definition do
      -> {
        router "/:id" do
          get ParameterizedCustomMatcher.new do
            send params[:id] || ""
          end
        end
      }
    end

    it "is matched" do
      expect(call("/123")[0]).to eq(200)
      expect(call("/123")[2].body.first).to eq("123")
    end

    it "is not matched" do
      expect(call("/123/foo")[0]).to eq(404)
    end
  end

  context "when a router is defined with a custom matcher" do
    class CustomRouterMatcher
      def match?(path)
        true
      end

      def sub(match, with)
      end
    end

    let :app_definition do
      -> {
        router CustomRouterMatcher.new do
          get "/foo" do
            send "foo"
          end
        end
      }
    end

    it "is matched" do
      expect(call("/foo")[0]).to eq(200)
      expect(call("/foo")[2].body.first).to eq("foo")
    end
  end

  context "when a namespace is defined with a custom matcher" do
    it "is matched"
  end
end
