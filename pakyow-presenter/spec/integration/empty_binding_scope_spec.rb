RSpec.describe "empty binding scope that has no props" do
  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
      <div binding="post" version="empty">
        no posts
      </div>
      HTML
    )
  end

  it "still appears to be a scope" do
    expect(view.binding_scopes.count).to eq(1)
  end
end
