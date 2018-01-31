RSpec.describe "grouped routes" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller do
        action :foo

        def foo
        end

        group :g do
          action :bar

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          default do
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

  it "calls the actions and route in order" do
    call

    expect($calls[0]).to eq(:foo)
    expect($calls[1]).to eq(:bar)
    expect($calls[2]).to eq(:route)
  end
end
