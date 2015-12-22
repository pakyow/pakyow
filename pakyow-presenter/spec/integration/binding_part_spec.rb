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
    end

    it "defines multiple parts" do
      # TODO test class is applied
      expect(data).to have_key :href 
      expect(data).to have_key :content 
      expect(data[:href].call()).to eq "/path/to/foo/bar"
      expect(data[:content].call()).to eq "Link to foo bar"
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
