VIEW_PATH = File.join(File.expand_path('../', __FILE__), 'views')

Pakyow::App.define do
  configure(:test) do
    presenter.view_stores = {
      default: VIEW_PATH,
      test: VIEW_PATH
    }
  end

  processor(:foo, :bar) do |data|
    data.gsub('bar', 'foo')
  end
end
