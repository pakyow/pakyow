require "rspec-benchmark"
require "securerandom"

RSpec.describe "routing performance", benchmark: true do
  include RSpec::Benchmark::Matchers

  include_context "app"

  context "with a simple route" do
    let :app_definition do
      Proc.new {
        controller do
          default do; end
        end
      }
    end

    it "performs" do
      expect {
        call
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with a single deeply nested route" do
    let :app_definition do
      Proc.new {
        controller :api, "/api" do
          namespace :project, "/projects" do
            default do; end
          end
        end
      }
    end

    it "performs" do
      expect {
        call("/api/projects")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with a single parameterized route" do
    let :app_definition do
      Proc.new {
        controller do
          get "/:foo" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/bar")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with a single formatted route" do
    let :app_definition do
      Proc.new {
        controller do
          get "/foo.json|xml" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo.json")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with a single regex route" do
    let :app_definition do
      Proc.new {
        controller do
          get(/(.*)/) do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with many simple routes" do
    let :app_definition do
      Proc.new {
        controller do
          1_000.times do
            send [:get, :put, :post, :patch, :delete].sample, SecureRandom.hex do; end
          end

          get "/foo" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with many parameterized routes" do
    let :app_definition do
      Proc.new {
        controller do
          1_000.times do
            send [:get, :put, :post, :patch, :delete].sample, "#{SecureRandom.hex}/:id" do; end
          end

          get "/foo/:id" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo/123")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with many formatted routes" do
    let :app_definition do
      Proc.new {
        controller do
          1_000.times do
            send [:get, :put, :post, :patch, :delete].sample, "#{SecureRandom.hex}.json|xml" do; end
          end

          get "/foo.json|xml" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo.json")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end

  context "with many regex routes" do
    let :app_definition do
      Proc.new {
        controller do
          1_000.times do
            send [:get, :put, :post, :patch, :delete].sample, /^#{SecureRandom.hex}^/ do; end
          end

          get "/foo" do; end
        end
      }
    end

    it "performs" do
      expect {
        call("/foo")
      }.to perform_at_least(2000, time: 2.0, warmup: 1.0).ips
    end
  end
end
