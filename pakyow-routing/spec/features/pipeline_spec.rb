RSpec.describe "controller pipelines" do
  include_context "app"

  before do
    $calls = []; call
  end

  context "when a single action is defined" do
    let :app_init do
      Proc.new do
        controller do
          action :foo

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end
        end
      end
    end

    it "calls in order" do
      expected_calls = [
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when multiple actions are defined" do
    let :app_init do
      Proc.new do
        controller do
          action :foo
          action :bar
          action :baz

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
        :foo,
        :bar,
        :baz,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when the action method is defined in a parent controller" do
    let :app_init do
      Proc.new {
        controller do
          def foo
            $calls << :foo
          end

          namespace :ns, "/" do
            action :foo

            default do
              $calls << :route
            end
          end
        end
      }
    end

    it "calls in order" do
      expected_calls = [
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when actions are defined on a parent controller" do
    let :app_init do
      Proc.new {
        controller do
          action :foo

          def foo
            $calls << :foo
          end

          group :group do
            action :sub_foo

            def sub_foo
              $calls << :sub_foo
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
        :foo,
        :sub_foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "when actions are defined in a template" do
    let :app_init do
      Proc.new {
        controller do
          template :call_foo do
            action :foo
          end

          call_foo do
            def foo
              $calls << :foo
            end

            default do
              $calls << :route
            end
          end
        end
      }
    end

    it "extends the controller pipeline" do
      expected_calls = [
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "defining an action only for some routes" do
    let :app_init do
      Proc.new {
        controller do
          action :foo, only: [:default]

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end

          get "/other" do
            $calls << :other
          end
        end
      }
    end

    it "calls the action for specified route" do
      expected_calls = [
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "does not call the action for unspecified routes" do
      $calls = []
      call("/other")
      expected_calls = [
        :other
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "defining an action that skips some routes" do
    let :app_init do
      Proc.new {
        controller do
          action :foo, skip: [:default]

          def foo
            $calls << :foo
          end

          default do
            $calls << :route
          end

          get "/other" do
            $calls << :other
          end
        end
      }
    end

    it "does not call the action for skipped routes" do
      expected_calls = [
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "calls the action for unskipped routes" do
      $calls = []
      call("/other")
      expected_calls = [
        :foo,
        :other
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "skipping an action" do
    let :app_init do
      Proc.new {
        controller do
          action :foo

          def foo
            $calls << :foo
          end

          skip_action :foo

          default do
            $calls << :route
          end

          get "/other" do
            $calls << :other
          end
        end
      }
    end

    it "does not call the action" do
      expected_calls = [
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end

      $calls = []
      call("/other")
      expected_calls = [
        :other
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "skipping an action only for some routes" do
    let :app_init do
      Proc.new {
        controller do
          action :foo

          def foo
            $calls << :foo
          end

          skip_action :foo, only: [:default]

          default do
            $calls << :route
          end

          get "/other" do
            $calls << :other
          end
        end
      }
    end

    it "does not call the action for skipped routes" do
      expected_calls = [
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "calls the action for unskipped routes" do
      $calls = []
      call("/other")
      expected_calls = [
        :foo,
        :other
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "skipping an action before the action is defined" do
    let :app_init do
      Proc.new {
        controller do
          skip_action :bar

          action :foo do
            $calls << :foo
          end

          action :bar do
            $calls << :bar
          end

          default do
            $calls << :route
          end
        end
      }
    end

    it "does not call the action" do
      expected_calls = [
        :foo, :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "using another pipeline module" do
    let :app_init do
      Proc.new {
        controller do
          action :bar

          pipeline :foo do
            action :foo
          end

          use_pipeline :foo

          default do
            $calls << :route
          end

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end
        end
      }
    end

    it "replaces the current pipeline with the one that was used" do
      expected_calls = [
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "including a pipeline" do
    let :app_init do
      Proc.new {
        controller do
          action :bar

          pipeline :foo do
            action :foo
          end

          include_pipeline :foo

          default do
            $calls << :route
          end

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end
        end
      }
    end

    it "includes actions from the included pipeline" do
      expected_calls = [
        :bar,
        :foo,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "excluding a pipeline" do
    let :app_init do
      Proc.new {
        controller do
          action :foo
          action :bar

          pipeline :foo do
            action :foo
          end

          exclude_pipeline :foo

          default do
            $calls << :route
          end

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end
        end
      }
    end

    it "excludes actions from the excluded pipeline" do
      expected_calls = [
        :bar,
        :route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end

  context "using an externally defined pipeline" do
    it "needs a test case"
  end

  context "including an externally defined pipeline" do
    it "needs a test case"
  end

  context "excluding an externally defined pipeline" do
    it "needs a test case"
  end

  describe "defining an action with the same name for different routes" do
    let :app_init do
      Proc.new do
        controller do
          action :test_same_name, only: [:foo_route] do
            $calls << :foo_action
          end

          action :test_same_name_2, only: [:foo_route] do
            $calls << :foo_action_2
          end

          action :test_same_name, only: [:bar_route] do
            $calls << :bar_action
          end

          get :foo_route, "/foo" do
            $calls << :foo_route
          end

          get :bar_route, "/bar" do
            $calls << :bar_route
          end
        end
      end
    end

    it "calls the correct action for the first route" do
      call("/foo")

      expected_calls = [
        :foo_action,
        :foo_action_2,
        :foo_route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end

    it "calls the correct action for the second route" do
      call("/bar")

      expected_calls = [
        :bar_action,
        :bar_route
      ]

      expected_calls.each_with_index do |call, i|
        expect($calls[i]).to eq(call)
      end
    end
  end
end
