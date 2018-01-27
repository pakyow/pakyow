RSpec.describe "controller pipelines" do
  include_context "testable app"

  before do
    $calls = []; call
  end

  context "when a single action is defined" do
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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
    let :app_definition do
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

  context "using another pipeline module" do
    after do
      Object.send(:remove_const, :Foo)
    end

    let :app_definition do
      Proc.new {
        require "pakyow/support/pipeline"

        module Foo
          extend Pakyow::Support::Pipeline

          action :foo

          def foo
            $calls << :foo
          end
        end

        controller do
          action :bar

          def bar
            $calls << :bar
          end

          use_pipeline Foo

          default do
            $calls << :route
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
    after do
      Object.send(:remove_const, :Foo)
    end

    let :app_definition do
      Proc.new {
        require "pakyow/support/pipeline"

        module Foo
          extend Pakyow::Support::Pipeline

          action :foo

          def foo
            $calls << :foo
          end
        end

        controller do
          action :bar

          def bar
            $calls << :bar
          end

          include_pipeline Foo

          default do
            $calls << :route
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
    after do
      Object.send(:remove_const, :Foo)
    end

    let :app_definition do
      Proc.new {
        require "pakyow/support/pipeline"

        module Foo
          extend Pakyow::Support::Pipeline

          action :foo
        end

        controller do
          action :foo
          action :bar

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          exclude_pipeline Foo

          default do
            $calls << :route
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
end
