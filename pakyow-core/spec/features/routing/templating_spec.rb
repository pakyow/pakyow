RSpec.describe "route templating" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
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
end
