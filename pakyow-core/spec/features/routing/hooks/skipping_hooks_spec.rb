RSpec.describe "skipping hooks" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when an inline hook is defined to skip a named route" do
    let :app_definition do
      Proc.new do
        router do
          before skip: [:skippable] do
            $calls << :before
          end

          default do
            $calls << :route
          end

          get :skippable, "/skippable" do
            $calls << :route_skippable
          end
        end
      end
    end

    it "is not called for the skipped route" do
      $calls = []; call("/skippable")
      expect($calls[0]).to eq(:route_skippable)
    end

    it "is called for non-skipped routes" do
      expect($calls[0]).to eq(:before)
      expect($calls[1]).to eq(:route)
    end
  end

  context "when an inline hook is defined to skip with the result of a proc" do
    let :app_definition do
      Proc.new do
        router do
          before skip: -> { req.path.include?("skip") } do
            $calls << :before
          end

          default do
            $calls << :route
          end

          get :skippable, "/skippable" do
            $calls << :route_skippable
          end
        end
      end
    end

    it "is not called when the proc evaluates to true" do
      $calls = []; call("/skippable")
      expect($calls[0]).to eq(:route_skippable)
    end

    it "is called for the route when the proc evaluates to false" do
      expect($calls[0]).to eq(:before)
      expect($calls[1]).to eq(:route)
    end
  end

  context "when a route is defined to skip a named hook" do
    let :app_definition do
      Proc.new do
        router do
          before :foo
          after :foo
          around :foo

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end

          get :skippable, "/skippable", skip: [:foo] do
            $calls << :route_skippable
          end
        end
      end
    end

    it "is not called for the route that skipped it" do
      $calls = []; call("/skippable")
      expect($calls[0]).to eq(:route_skippable)
    end

    it "is called before other routes" do
      expected_calls = [
        :foo,
        :foo,
        :route,
        :foo,
        :foo
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when a route is defined to skip a named before hook" do
    let :app_definition do
      Proc.new do
        router do
          before :foo
          after :foo
          around :foo

          def foo
            $calls << :foo
          end

          default skip_before: [:foo] do
            $calls << :route
          end
        end
      end
    end

    it "is not called before the route that skipped it" do
      expected_calls = [
        :foo,
        :route,
        :foo,
        :foo
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when a route is defined to skip a named after hook" do
    let :app_definition do
      Proc.new do
        router do
          before :foo
          after :foo
          around :foo

          def foo
            $calls << :foo
          end

          default skip_after: [:foo] do
            $calls << :route
          end
        end
      end
    end

    it "is not called after the route that skipped it" do
      expected_calls = [
        :foo,
        :foo,
        :route,
        :foo
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when a route is defined to skip a named around hook" do
    let :app_definition do
      Proc.new do
        router do
          before :foo
          after :foo
          around :foo

          def foo
            $calls << :foo
          end

          default skip_around: [:foo] do
            $calls << :route
          end
        end
      end
    end

    it "is not called around the route that skipped it" do
      expected_calls = [
        :foo,
        :route,
        :foo
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end
end
