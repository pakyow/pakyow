require_relative "./shared"

RSpec.describe "populating options for nested data" do
  include_context "options_for"

  let :view_path do
    "/presentation/forms/options_for/nested_data"
  end

  let :options do
    [
      { description: "foo", enabled: true, name: "Foo" },
      { description: "bar", enabled: false, name: "Bar" }
    ]
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  def sign(value)
    Pakyow::Support::MessageVerifier.new.sign(value.to_s)
  end

  it "sets up the fields and labels" do
    expect(rendered).to include_sans_whitespace(
      <<~HTML
        <form data-b="post:form">
          <ul>
            <li data-b="tags">
              <label data-b="name">Foo</label>
              <input type="text" data-b="description" value="foo" name="post[tags][][description]">
              <input type="checkbox" data-b="enabled" value="true" name="post[tags][][enabled]">
            </li>

            <li data-b="tags">
              <label data-b="name">Bar</label>
              <input type="text" data-b="description" value="bar" name="post[tags][][description]">
              <input type="checkbox" data-b="enabled" value="true" name="post[tags][][enabled]">
            </li>

            <script type="text/template" data-b="tags">
              <li data-b="tags">
                <label data-b="name">
                  Tag Name
                </label>

                <input type="text" data-b="description">
                <input type="checkbox" data-b="enabled" value="true">
              </li>
            </script>
          </ul>
        </form>
      HTML
    )
  end

  describe "embedding the unique identifier" do
    context "nested data has an id" do
      include_context "app"

      let :app_init do
        Proc.new do
          presenter "/form/nested_data_id" do
            options_for :post, :tags do
              [
                { id: 1 },
                { id: 2 }
              ]
            end
          end
        end
      end

      it "embeds the signed id" do
        html = call("/form/nested_data_id")[2]

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-id="1">
              <input type="hidden" name="post[tags][][id]" value="#{sign(1)}">
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags" data-id="2">
              <input type="hidden" name="post[tags][][id]" value="#{sign(2)}">
          HTML
        )
      end
    end

    context "nested data has a primary key" do
      let :object do
        require "pakyow/support/bindable"

        Class.new do
          include Pakyow::Support::Bindable

          def self.primary_key_field
            :slug
          end

          def initialize(values)
            @values = values
          end

          def method_missing(method, *args)
            if @values.include?(method)
              @values[method]
            else
              super
            end
          end

          def respond_to_missing?(method, *args)
            @values.include?(method) || super
          end
        end
      end

      include_context "app"

      let :app_init do
        local = self

        Proc.new do
          presenter "/form/nested_data_id" do
            options_for :post, :tags do
              [
                local.object.new(slug: :one),
                local.object.new(slug: :two)
              ]
            end
          end
        end
      end

      it "embeds the signed primary key" do
        html = call("/form/nested_data_id")[2]

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags">
              <input type="hidden" name="post[tags][][slug]" value="#{sign('one')}">
          HTML
        )

        expect(html).to include_sans_whitespace(
          <<~HTML
            <li data-b="tags">
              <input type="hidden" name="post[tags][][slug]" value="#{sign('two')}">
          HTML
        )
      end
    end

    context "nested data does not have an id or primary key" do
      let :options do
        [
          { foo: 1 },
          { foo: 2 }
        ]
      end

      it "does not embed an identifier" do
        expect(rendered).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
              <ul>
                <li data-b="tags">
                  <input type="text" data-b="description" name="post[tags][][description]">
                  <input type="checkbox" data-b="enabled" value="true" name="post[tags][][enabled]">
                </li>

                <li data-b="tags">
                  <input type="text" data-b="description" name="post[tags][][description]">
                  <input type="checkbox" data-b="enabled" value="true" name="post[tags][][enabled]">
                </li>

                <script type="text/template" data-b="tags">
                  <li data-b="tags">
                    <label data-b="name">Tag Name</label>
                    <input type="text" data-b="description">
                    <input type="checkbox" data-b="enabled" value="true">
                  </li>
                </script>
              </ul>
            </form>
          HTML
        )
      end
    end
  end

  describe "populating options for a single nested object" do
    include_context "app"

      let :app_init do
        local = self

        Proc.new do
          presenter "/form/nested_data_id" do
            options_for :post, :tags do
              { id: 1, description: "foo", enabled: true, name: "Foo" }
            end
          end
        end
      end

    it "sets up the field and label for the object" do
      html = call("/form/nested_data_id")[2]
      expect(html.scan(/\<li data-b=\"tags\" data-id=\"/).count).to eq(1)
      expect(html).to include_sans_whitespace(
        <<~HTML
          <li data-b="tags" data-id="1">
            <input type="hidden" name="post[tags][id]" value="#{sign(1)}">
            <label data-b="name">Foo</label>
            <input type="text" data-b="description" value="foo" name="post[tags][description]">
            <input type="checkbox" data-b="enabled" value="true" name="post[tags][enabled]">
          </li>
        HTML
      )
    end
  end

  describe "populating options for an empty array" do
    let :options do
      []
    end

    it "clears the options" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <ul>
              <script type="text/template" data-b="tags">
                <li data-b="tags">
                  <label data-b="name">Tag Name</label>
                  <input type="text" data-b="description">
                  <input type="checkbox" data-b="enabled" value="true">
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end
  end

  describe "populating options for nil" do
    let :options do
      nil
    end

    it "clears the options" do
      expect(rendered).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form">
            <ul>
              <script type="text/template" data-b="tags">
                <li data-b="tags">
                  <label data-b="name">Tag Name</label>
                  <input type="text" data-b="description">
                  <input type="checkbox" data-b="enabled" value="true">
                </li>
              </script>
            </ul>
          </form>
        HTML
      )
    end
  end
end
