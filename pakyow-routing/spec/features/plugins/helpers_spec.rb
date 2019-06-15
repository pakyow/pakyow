require "pakyow/plugin"

RSpec.describe "calling plugin helpers from a controller" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable
      plug :testable, as: :foo

      controller do
        get "/helper" do
          send testable.test
        end

        get "/helper/named" do
          send testable(:foo).test
        end
      end
    end
  end

  it "calls helpers for default instances" do
    expect(call("/helper")[2]).to eq("testable(default)")
  end

  it "calls helpers for named instances" do
    expect(call("/helper/named")[2]).to eq("testable(foo)")
  end
end
