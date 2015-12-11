require 'support/helper'
#require 'core/app'

describe Pakyow::App, '#resource' do
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = Pakyow::AppContext.new(mock_request, mock_response)
  end

  context 'called with a resource name, path, and block' do
    before do
      Pakyow.app.resource :test, "tests" do
        list do
        end
      end
    end

    it 'creates a route set for the resource name' do
      expect(Pakyow::Router.instance.sets[:test]).to be_kind_of Pakyow::RouteSet
    end

    describe 'the route set block' do
      let(:route_set_block) { Pakyow.app.routes[:test] }

      it 'exists' do
        expect(route_set_block).to be_kind_of Proc 
      end

      context 'when evaluated' do
        let(:set) { Pakyow::RouteSet.new }

        it 'creates restful routes with resource name, path, and block' do
          set.eval(&route_set_block)

          expect(set.match("tests", :get)).not_to be_nil
        end
      end
    end
  end

  context 'called without a block' do
    before do
      Pakyow::App.routes :test do
        restful :test, "tests" do
          list do
          end
        end
      end
    end

    it 'returns the route set matching the resource name' do
      expect(Pakyow.app.resource(:test)).to eq Pakyow::App.routes[:test]
    end
  end

  context 'called without a path' do
    it 'raises an ArgumentError' do
      no_path_passed = Proc.new { Pakyow.app.resource(:test) {} }
      nil_path_passed = Proc.new { Pakyow.app.resource(:test, nil) {} }
      expect(no_path_passed).to raise_error ArgumentError
      expect(nil_path_passed).to raise_error ArgumentError
    end
  end

  context 'called without a resource name' do
    it 'raises an ArgumentError' do
      no_name_passed = Proc.new { Pakyow.app.resource() {} }
      nil_name_passed = Proc.new { Pakyow.app.resource(nil, "tests") {} }
      expect(no_name_passed).to raise_error ArgumentError
      expect(nil_name_passed).to raise_error ArgumentError
    end
  end
end
