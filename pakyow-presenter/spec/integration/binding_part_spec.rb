require_relative 'support/int_helper'
require_relative 'support/helpers/req_res_helpers'

describe 'defining a binding part' do
  include ReqResHelpers
  include SetupHelper

  let :app do
    Pakyow.app
  end

  let :presenter do
    app.presenter
  end

  let :binder do
    presenter.binder
  end

  let(:data) do
    binder.value_for_scoped_prop(:foo, :bar, {}, {}, @context)
  end 

  before :each do
    setup
  end

  after do
    teardown
  end

  describe "defining a single binding part" do
    before do
      app.bindings do 
        scope :foo do
          binding :bar do
            part :href do
              "/path/to/foo/bar"
            end
          end
        end
      end
      presenter.load
    end

    it "defines a part of a binding" do
      expect(data).to have_key :href 
    end
  end

  describe 'defining multiple parts' do
    before do
      app.bindings do 
        scope :foo do
          binding :bar do
            part :href do
              "/path/to/foo/bar"
            end
            part :content do
              "Link to foo bar"
            end
            part :class do |klass|
              klass.ensure("bacon")
              klass.deny("lettus")
            end
          end
        end
      end
      presenter.load
      view.bind({})
    end

    let(:view) do
      Pakyow::Presenter::View.new("<div data-scope=\"foo\"><a data-prop=\"bar\" class=\"lettus tomato burger\">Test Link</a></div>")
    end

    let(:class_value) do
      view.scope(:foo).prop(:bar).attrs.first.instance_eval("get_attribute(:class)").value
    end

    let(:content_value) do
      view.scope(:foo).prop(:bar).html.join
    end

    let(:href_value) do
      view.scope(:foo).prop(:bar).attrs.first.instance_eval("get_attribute(:href)").value
    end

    it "defines multiple parts" do
      expect(data).to have_key :href 
      expect(data).to have_key :content 
      expect(data[:href].call()).to eq "/path/to/foo/bar"
      expect(data[:content].call()).to eq "Link to foo bar"

      # TODO test class is applied in a better way
      expect(class_value - %w{ tomato burger bacon }).to be_empty
      expect(class_value).to include "bacon"
    end

    describe "using data-parts" do
      let(:view) do
        Pakyow::Presenter::View.new("<div data-scope=\"foo\"><a data-prop=\"bar\" data-parts=\"class\" class=\"lettus tomato burger\">Test Link</a></div>")
      end

      it "binds some parts to the view" do
        expect(class_value).to eq %w{ tomato burger bacon }
        expect(href_value).to be_empty
        expect(content_value).to eq "Test Link"
      end
    end

    describe "using data-parts-exclude" do
      let(:view) do
        Pakyow::Presenter::View.new("<div data-scope=\"foo\"><a data-prop=\"bar\" data-parts-exclude=\"class\" class=\"lettus tomato burger\">Test Link</a></div>")
      end

      it "doesnt bind other parts to the view" do
        expect(class_value).to eq %w{ lettus tomato burger }
        expect(href_value).to eq "/path/to/foo/bar"
        expect(content_value).to eq "Link to foo bar"
      end
    end
  end

  describe 'hashes are ignored in bindings' do
    before do
      app.bindings do 
        scope :foo do
          binding :bar do
            part :href do
              "/path/to/foo/bar"
            end
            { href: "/another/path", content: "Something else" }
            part :content do
              "Link to foo bar"
            end
            { href: "/another/path", content: "Something else" }
          end
        end
      end
      presenter.load
    end

    it "ignores hashes in bindings" do
      expect(data[:href].call()).to eq "/path/to/foo/bar"
      expect(data[:content].call()).to eq "Link to foo bar"
      expect(data.keys).to eq [:href, :content]
    end
  end
end
