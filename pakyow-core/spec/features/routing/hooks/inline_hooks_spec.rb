RSpec.describe "inline hooks" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when defined as a proc for all routes" do
    let :app_definition do
      Proc.new do
        router do
          before do
            $calls << :before
          end

          default do
            $calls << :route
          end
        end
      end
    end

    it "is called" do
      expected_calls = [
        :before,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when defined as a proc for one named route" do
    let :app_definition do
      Proc.new do
        router do
          before :default do
            $calls << :before
          end

          default do
            $calls << :route
          end

          get :other, "/other" do
            $calls << :route_other
          end
        end
      end
    end

    it "is called for the defined route" do
      expected_calls = [
        :before,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "is not called for other routes" do
      $calls = []; call("/other")
      expect($calls[0]).to eq(:route_other)
    end
  end

  context "when defined as a proc for multiple named routes" do
    let :app_definition do
      Proc.new do
        router do
          before :default, :other do
            $calls << :before
          end

          default do
            $calls << :route
          end

          get :other, "/other" do
            $calls << :route_other
          end

          get :yet_another, "/yet_another" do
            $calls << :route_yet_another
          end
        end
      end
    end

    it "is called for the defined routes" do
      expected_calls = [
        :before,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end

      $calls = []; call("/other")
      expect($calls[0]).to eq(:before)
      expect($calls[1]).to eq(:route_other)
    end

    it "is not called for other routes" do
      $calls = []; call("/yet_another")
      expect($calls[0]).to eq(:route_yet_another)
    end
  end

  context "when defined as a method call for all routes" do
    let :app_definition do
      Proc.new do
        router do
          before :foo

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end
        end
      end
    end

    it "is called" do
      expected_calls = [
        :foo,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when defined as a method call for one named route" do
    let :app_definition do
      Proc.new do
        router do
          before :default, :foo

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end

          get :other, "/other" do
            $calls << :route_other
          end
        end
      end
    end

    it "is called for the defined route" do
      expected_calls = [
        :foo,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "is not called for other routes" do
      $calls = []; call("/other")
      expect($calls[0]).to eq(:route_other)
    end
  end

  context "when defined as a method call for multiple named routes" do
    let :app_definition do
      Proc.new do
        router do
          before :default, :other, :foo

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end

          get :other, "/other" do
            $calls << :route_other
          end

          get :yet_another, "/yet_another" do
            $calls << :route_yet_another
          end
        end
      end
    end

    it "is called for the defined routes" do
      expected_calls = [
        :foo,
        :route,
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end

      $calls = []; call("/other")
      expect($calls[0]).to eq(:foo)
      expect($calls[1]).to eq(:route_other)
    end

    it "is not called for other routes" do
      $calls = []; call("/yet_another")
      expect($calls[0]).to eq(:route_yet_another)
    end
  end
end
