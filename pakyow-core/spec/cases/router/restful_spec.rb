require_relative '../../support/helper'

describe 'restful route'do
  include ReqResHelpers
  include RouteTestHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = AppContext.new(mock_request, mock_response)
  end

  context 'action' do
    let(:set) { RouteSet.new }

    before do
      fn = lambda {}
      set.eval {
        restful :test, 'tests' do
          [:list, :new, :create, :edit, :update, :replace, :show, :remove].each { |a|
            self.send(a, &fn(:list))
          }
        end
      }
    end

    it 'list is supported' do
      expect(match: set.match('tests', :get)).to have_same_path(path: 'tests')
      expect(match: set.match('tests', :get)).to have_same_name(name: :list)
    end

    it 'new is supported' do
      expect(match: set.match('tests/new', :get)).to have_same_path(path: 'tests/new')
      expect(match: set.match('tests/new', :get)).to have_same_name(name: :new)
    end

    it 'create is supported' do
      expect(match: set.match('tests', :post)).to have_same_path(path: 'tests')
      expect(match: set.match('tests', :post)).to have_same_name(name: :create)
    end

    it 'edit is supported' do
      expect(match: set.match('tests/1/edit', :get)).to have_same_path(path: 'tests/:test_id/edit')
      expect(match: set.match('tests/1/edit', :get)).to have_same_name(name: :edit)
    end

    it 'update is supported' do
      expect(match: set.match('tests/1', :patch)).to have_same_path(path: 'tests/:test_id')
      expect(match: set.match('tests/1', :patch)).to have_same_name(name: :update)
    end

    it 'replace is supported' do
      expect(match: set.match('tests/1', :put)).to have_same_path(path: 'tests/:test_id')
      expect(match: set.match('tests/1', :put)).to have_same_name(name: :replace)
    end

    it 'show is supported do' do
      expect(match: set.match('tests/1', :get)).to have_same_path(path: 'tests/:test_id')
      expect(match: set.match('tests/1', :get)).to have_same_name(name: :show)
    end

    it 'remove is supported do' do
      expect(match: set.match('tests/1', :delete)).to have_same_path(path: 'tests/:test_id')
      expect(match: set.match('tests/1', :delete)).to have_same_name(name: :remove)
    end
  end


  it 'routes defined for passed actions only' do
    set = RouteSet.new

    fn = lambda {}
    set.eval {
      restful :test, 'tests' do
        action :list, &fn
      end
    }

    expect(match: set.match('tests', :get)).to  have_same_path path: 'tests'
    expect(match: set.match('tests', :get)).to  have_same_name name: :list
    expect(set.match('tests', :post)).to be_nil
  end

  it 'supports member routes' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        member do
          get 'foo', &fn
        end
      end
    }

    expect(match: set.match('tests/1/foo', :get)).to have_same_path path: 'tests/:test_id/foo'
  end

  it 'supports collection routes' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        collection do
          get 'foo', &fn
        end
      end
    }

    expect(match: set.match('tests/foo', :get)).to have_same_path path: 'tests/foo'
  end

  it 'supports collection routes with show action first' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        show do; end

        collection do
          get 'foo', &fn
        end
      end
    }

    expect(match: set.match('tests/foo', :get)).to have_same_path path: 'tests/foo'
  end

  it 'supports show action route last' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        collection do
          get 'foo', &fn
        end
        show do; end
      end
    }

    expect(match: set.match('tests/foo', :get)).to have_same_path path: 'tests/foo'
  end

  it 'supports nested resources' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        restful :nest, 'nests' do
          action :list, &fn
        end
      end
   }

    expect(match: set.match('tests/1/nests', :get)).to have_same_path path: 'tests/:test_id/nests'
  end

  it 'show view path' do
    skip
  end

  it 'show and new do not conflict' do
    set = RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        action :show do; end
        action :new do; end
      end
    }

    expect(match: set.match('tests/new', :get)).to have_same_path path: 'tests/new'
  end
end
