require_relative '../../support/helper'

describe 'restful route'do
  include ReqResHelpers
  include RouteTestHelpers

  before do
    Pakyow::App.stage(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))
  end

  context 'action' do
    let(:set) { Pakyow::RouteSet.new }

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
    set = Pakyow::RouteSet.new

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
    set = Pakyow::RouteSet.new
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
    set = Pakyow::RouteSet.new
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
    set = Pakyow::RouteSet.new
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
    set = Pakyow::RouteSet.new
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
    set = Pakyow::RouteSet.new
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
    set = Pakyow::RouteSet.new
    fn = lambda {}

    set.eval {
      restful :test, 'tests' do
        action :show do; end
        action :new do; end
      end
    }

    expect(match: set.match('tests/new', :get)).to have_same_path path: 'tests/new'
  end

  describe 'action hook order' do
    let :set do
      Pakyow::RouteSet.new
    end

    let :fn1 do
      lambda {}
    end

    let :fn2 do
      lambda {}
    end

    let :fn3 do
      lambda {}
    end

    let :fn4 do
      lambda {}
    end

    let :fns do
      set.match('/tests', :get)[0][3]
    end

    before do
      fn1 = self.fn1
      fn2 = self.fn2
      fn3 = self.fn3
      fn4 = self.fn4

      set.eval do
        fn :fn1, &fn1
        fn :fn2, &fn2
        fn :fn3, &fn3
        fn :fn4, &fn4

        restful :test, 'tests', before: [:fn1], after: [:fn4] do
          list before: [:fn2], after: [:fn3] do; end
        end
      end
    end

    it 'calls restful before hooks first' do
      expect(fns[0]).to eq fn1
    end

    it 'calls action before hooks after restful before hooks' do
      expect(fns[1]).to eq fn2
    end

    it 'calls action after hooks before restful after hooks'
    it 'calls restful after hooks last'
  end

  describe 'member routes' do
    let :set do
      Pakyow::RouteSet.new
    end

    let :fn1 do
      lambda {}
    end

    let :fn2 do
      lambda {}
    end

    before do
      fn1 = self.fn1
      fn2 = self.fn2

      set.eval do
        fn :fn1, &fn1
        fn :fn2, &fn2

        restful :test, 'tests' do
          member before: [:fn1] do
            get :foo, 'foo', before: [:fn2] do; end
          end
        end
      end
    end

    it 'executes functions in order' do
      fns = set.match('/tests/1/foo', :get)[0][3]

      expect(fns[0]).to eq fn1
      expect(fns[1]).to eq fn2
    end
  end

  describe 'collection routes' do
    let :set do
      Pakyow::RouteSet.new
    end

    let :fn1 do
      lambda {}
    end

    let :fn2 do
      lambda {}
    end

    before do
      fn1 = self.fn1
      fn2 = self.fn2

      set.eval do
        fn :fn1, &fn1
        fn :fn2, &fn2

        restful :test, 'tests' do
          collection before: [:fn1] do
            get :foo, 'foo', before: [:fn2] do; end
          end
        end
      end
    end

    it 'executes functions in order' do
      fns = set.match('/tests/foo', :get)[0][3]

      expect(fns[0]).to eq fn1
      expect(fns[1]).to eq fn2
    end
  end
end
