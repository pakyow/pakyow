Pakyow::App.define do
  configure(:test) do
    presenter.view_stores = {
      default: "spec/support/views/",
      test: "spec/support/views/"
    }
  end

  processor(:foo, :bar) do |data|
    data.gsub('bar', 'foo')
  end
end
