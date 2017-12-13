RSpec.describe "route templating" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      controller do
        template :talkback do
          get :hello, "/hello"
          get :goodbye, "/goodbye"
        end

        talkback :en, "/en" do
          hello do
            send "hello"
          end

          goodbye do
            send "goodbye"
          end

          get "/thanks" do
            send "thanks"
          end
        end

        talkback :fr, "/fr" do
          hello do
            send "bonjour"
          end
        end
      end
    }
  end

  it "creates routes from the template" do
    expect(call("/en/hello")[2].body.first).to eq("hello")
    expect(call("/en/goodbye")[2].body.first).to eq("goodbye")
    expect(call("/fr/hello")[2].body.first).to eq("bonjour")
  end

  it "extends the template with routes" do
    expect(call("/en/thanks")[2].body.first).to eq("thanks")
  end

  context "when the template defines hooks" do
    let :app_definition do
      Proc.new {
        controller do
          template :hooktest do
            get :perform, "/", before: [:foo, Proc.new { $calls << :bar }]
          end

          hooktest :test, "/test" do
            def foo
              $calls << :foo
            end

            def baz
              $calls << :baz
            end

            perform before: [:baz], skip: [:foo] do
              $calls << :perform
            end
          end
        end
      }
    end

    before do
      $calls = []
    end

    it "calls the hooks" do
      expect(call("/test")[0]).to eq(200)

      expect($calls[0]).to eq(:baz)
      expect($calls[1]).to eq(:foo)
      expect($calls[2]).to eq(:bar)
      expect($calls[3]).to eq(:perform)
    end
  end
end
