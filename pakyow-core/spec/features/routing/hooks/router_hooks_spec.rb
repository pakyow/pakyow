RSpec.describe "controller hooks" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when a single hook is defined" do
    let :app_definition do
      Proc.new do
        controller before: :foo, after: :bar, around: :baz do
          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          def baz
            $calls << :baz
          end

          default do
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
        controller before: [:foo1, :foo2], after: [:bar1, :bar2], around: [:baz1, :baz2] do
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

          default do
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

  context "when a hook is defined in a parent controller" do
    let :app_definition do
      Proc.new {
        controller do
          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          def baz
            $calls << :baz
          end

          namespace :ns, "/", before: [:foo], after: [:bar], around: [:baz] do
            default do
              $calls << :route
            end
          end
        end
      }
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

  context "when hooks are defined on a parent controller" do
    let :app_definition do
      Proc.new {
        controller before: [:foo], after: [:bar], around: [:baz] do
          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          def baz
            $calls << :baz
          end

          group :group, before: [:sub_foo], after: [:sub_bar], around: [:sub_baz] do
            def sub_foo
              $calls << :sub_foo
            end

            def sub_bar
              $calls << :sub_bar
            end

            def sub_baz
              $calls << :sub_baz
            end

            default do
              $calls << :route
            end
          end
        end
      }
    end

    it "calls in order" do
      expected_calls = [
        :baz,
        :sub_baz,
        :foo,
        :sub_foo,
        :route,
        :bar,
        :sub_bar,
        :baz,
        :sub_baz
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end
end
