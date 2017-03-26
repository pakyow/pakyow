RSpec.describe "namespaced routes" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
        namespace :ns, "/ns", before: [:foo], after: [:foo], around: [:meh] do
          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          def baz
            $calls << :baz
          end

          def meh
            $calls << :meh
          end

          default before: [:bar], after: [:baz] do
            $calls << :route
          end
        end
      end
    }
  end

  before do
    $calls = []
  end

  it "is called" do
    expect(call("/ns")[0]).to eq(200)
  end

  it "calls the hooks and route in order" do
    call("/ns")

    expect($calls[0]).to eq(:meh)
    expect($calls[1]).to eq(:foo)
    expect($calls[2]).to eq(:bar)
    expect($calls[3]).to eq(:route)
    expect($calls[4]).to eq(:foo)
    expect($calls[5]).to eq(:baz)
    expect($calls[6]).to eq(:meh)
  end

  context "when a route is defined in a parameterized namespace" do
    let :app_definition do
      -> {
        router do
          namespace :ns, "/ns/:id" do
            default do
              send params[:id] || ""
            end
          end
        end
      }
    end

    it "is called" do
      expect(call("/ns/123")[0]).to eq(200)
    end

    it "makes the parameters available to the route" do
      expect(call("/ns/123")[2].body.first).to eq("123")
    end
  end

  context "when a namespace is defined without a name" do
    let :app_definition do
      -> {
        router do
          namespace "/ns" do
            default do
              send "ns"
            end
          end
        end
      }
    end

    it "is called" do
      expect(call("/ns")[0]).to eq(200)
    end
  end
end
