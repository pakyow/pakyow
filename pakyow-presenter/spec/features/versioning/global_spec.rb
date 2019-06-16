RSpec.describe "global view versioning" do
  include_context "app"

  let :app_def do
    Proc.new do
      presenter "/presentation/versioning/multiple-without-default" do
        version :two do |object|
          object[:title].include?("two")
        end

        render :post do
          present([{ title: "one" }, { title: "two" }, { title: "three" }])
        end
      end
    end
  end

  it "uses the global version during presentation" do
    expect(call("/presentation/versioning/multiple-without-default")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post" data-v="one"><h1 data-b="title">one</h1></div>
        <div data-b="post" data-v="two"><h1 data-b="title">two</h1></div>
        <div data-b="post" data-v="one"><h1 data-b="title">three</h1></div>
      HTML
    )
  end
end
