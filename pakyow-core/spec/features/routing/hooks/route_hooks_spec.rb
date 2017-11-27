RSpec.describe "route hooks" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when a single hook is defined" do
    let :app_definition do
      Proc.new do
        router do
          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          def baz
            $calls << :baz
          end

          default before: :foo, after: :bar, around: :baz do
            $calls << :route
          end
        end
      end
    end

    it "calls in order" do
      expected_calls = [
        :baz,
        :foo,
        :route,
        :bar,
        :baz
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when multiple hooks are defined" do
    let :app_definition do
      Proc.new do
        router do
          def foo1
            $calls << :foo1
          end

          def bar1
            $calls << :bar1
          end

          def baz1
            $calls << :baz1
          end

          def foo2
            $calls << :foo2
          end

          def bar2
            $calls << :bar2
          end

          def baz2
            $calls << :baz2
          end

          default before: [:foo1, :foo2], after: [:bar1, :bar2], around: [:baz1, :baz2] do
            $calls << :route
          end
        end
      end
    end

    it "calls in order" do
      expected_calls = [
        :baz1,
        :baz2,
        :foo1,
        :foo2,
        :route,
        :bar1,
        :bar2,
        :baz1,
        :baz2
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end
end
