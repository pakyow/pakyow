RSpec.describe "grouped routes" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
        group :g, before: [:foo], after: [:foo], around: [:meh] do
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
    expect(call[0]).to eq(200)
  end

  it "calls the hooks and route in order" do
    call

    expect($calls[0]).to eq(:meh)
    expect($calls[1]).to eq(:foo)
    expect($calls[2]).to eq(:bar)
    expect($calls[3]).to eq(:route)
    expect($calls[4]).to eq(:foo)
    expect($calls[5]).to eq(:baz)
    expect($calls[6]).to eq(:meh)
  end
end
