require_relative '../../support/helper'

describe 'restful route'do
  include ReqResHelpers
  include RouteTestHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = Pakyow::AppContext.new(mock_request, mock_response)
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


  it 'restful routes can be defined using resources' do
    restful_set = Pakyow::RouteSet.new
    app = Pakyow.app
    routes = { get: %w{ tests tests/new tests/1/edit }, post: %w{ tests }, delete: %w{ tests/1 }, put: %w{ tests/1 } }
    # get: "tests/1" (:show) is a tricky route to compare with eq because
    # there is a proc there

    fn = lambda {}
    routes_fn = lambda {
      [:list, :new, :create, :edit, :update, :replace, :show, :remove].each { |a|
        self.send(a, &fn(:list))
      }
    }

    restful_set.eval { restful(:test, 'tests', &routes_fn) }

    app.resource(:test, 'tests', &routes_fn)
    resources_set = Pakyow::Router.instance.sets[:test]

    routes.each do |method, paths|
      paths.each do |path|
        restful_match = restful_set.match(path, method)
        resources_match = resources_set.match(path, method)
        expect(resources_match).to eq restful_match
      end
    end

    path = "tests/1"
    method = :get
    restful_match = restful_set.match(path, method)
    resources_match = resources_set.match(path, method)
    expect(resources_match[1..-1]).to eq restful_match[1..-1]
    restful_procs = restful_match[0].delete_at(3)
    resources_procs = resources_match[0].delete_at(3)
    expect(resources_match[0]).to eq restful_match[0]
    restful_procs.each_with_index do |restful_proc, i|
      expect(resources_procs[i].source_location).to eq restful_proc.source_location
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
