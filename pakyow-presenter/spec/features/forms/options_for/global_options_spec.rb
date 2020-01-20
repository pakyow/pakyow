RSpec.describe "defining global options in the presenter" do
  include_context "app"

  context "options are defined as a block" do
    let :app_def do
      local = self
      Proc.new do
        presenter "/presentation/forms/options_for/global_options" do
          options_for :post, :tag do
            local.instance_variable_set(:@context, self)

            [
              { id: 1, name: "foo" },
              { id: 2, name: "bar" },
              { id: 3, name: "baz" }
            ]
          end
        end
      end
    end

    it "applies the options to the form" do
      expect(call("/presentation/forms/options_for/global_options")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
        HTML
      )

      expect(call("/presentation/forms/options_for/global_options")[2]).to include_sans_whitespace(
        <<~HTML
          <select data-b="tag" name="post[tag]">
            <option value="1">foo</option>
            <option value="2">bar</option>
            <option value="3">baz</option>
          </select>
        HTML
      )
    end

    it "calls the block in context of the expected presenter instance" do
      call("/presentation/forms/options_for/global_options")
      expect(@context).to be_instance_of(Pakyow::Presenter::Presenters::Form)
      expect(@context.__getobj__.class.ancestors).to include(Test::Presenter)
    end
  end

  context "options are defined inline" do
    let :presenter_class do
      Class.new(Pakyow::Presenter::Presenter) do
        options_for :post, :tag, [
          { id: 1, name: "foo" },
          { id: 2, name: "bar" },
          { id: 3, name: "baz" }
        ]
      end
    end

    let :app_def do
      Proc.new do
        presenter "/presentation/forms/options_for/global_options" do
          options_for :post, :tag, [
            { id: 1, name: "foo" },
            { id: 2, name: "bar" },
            { id: 3, name: "baz" }
          ]
        end
      end
    end

    it "applies the options to the form" do
      expect(call("/presentation/forms/options_for/global_options")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
        HTML
      )

      expect(call("/presentation/forms/options_for/global_options")[2]).to include_sans_whitespace(
        <<~HTML
          <select data-b="tag" name="post[tag]">
            <option value="1">foo</option>
            <option value="2">bar</option>
            <option value="3">baz</option>
          </select>
        HTML
      )
    end
  end
end
