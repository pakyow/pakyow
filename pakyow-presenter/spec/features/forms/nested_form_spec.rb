RSpec.describe "presenting data with a nested form" do
  include_context "app"

  context "parent and child have the same prop" do
    let :app_def do
      Proc.new do
        presenter "/presentation/forms/nested" do
          render :post do
            present(body: "foo")
          end
        end
      end
    end

    it "presents the form correctly" do
      expect(call("/presentation/forms/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <input type="text" data-b="body" name="comment[body]"></form>
        HTML
      )
    end
  end
end
