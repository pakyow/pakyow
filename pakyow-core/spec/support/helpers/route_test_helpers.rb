require 'rspec/expectations'

module RouteTestHelpers
  extend RSpec::Matchers::DSL

  matcher :have_same_regex do |opts|
    match do |actual|
      m = actual[:match][0]
      regex = opts[:regex] == m[0]
    end
  end

  matcher :have_same_vars do |opts|
    match do |actual|
      m = actual[:match][0]
      vars  = opts[:vars]  == m[1]
    end
  end

  matcher :have_same_name do |opts|
    match do |actual|
      m = actual[:match][0]
      name  = m[2]  == opts[:name]
    end
  end

  matcher :have_same_fns do |opts|
    match do |actual|
      m = actual[:match][0]
      fns = opts[:fns] == m[3][0]
    end
  end

  matcher :have_same_path do |opts|
    match do |actual|
      m    = actual[:match][0]
      path = m[4] == opts[:path]
    end
  end

  matcher :have_same_handler do |data|
    match do |actual|
      name = actual[0]    == data[0]
      code = actual[1]    == data[1]
      fn   = actual[2][0] == data[2]
    end
  end
end
