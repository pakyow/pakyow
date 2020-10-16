RSpec.describe "forms that are componentized" do
  include_context "app"

  let :app_def do
    Proc.new do
      component :form do
        def perform
          expose "post:form", { id: 1, title: "foo" }
        end

        presenter do
          render do
          end
        end
      end
    end
  end

  it "is setup" do
    expect(call("/form/componentized")[2]).to include_sans_whitespace('<input type="hidden" name="pw-form"')
  end
end
