require 'rspec/expectations'

module RouteTestHelpers
  extend RSpec::Matchers::DSL

  matcher :have_same_regex do |opts|
    match do |actual|
      m = actual[:match][0]
      opts[:regex] == m[0]
    end
  end

  matcher :have_same_vars do |opts|
    match do |actual|
      m = actual[:match][0]
      opts[:vars]  == m[1]
    end
  end

  matcher :have_same_name do |opts|
    match do |actual|
      m = actual[:match][0]
      m[2] == opts[:name]
    end
  end

  matcher :have_same_fns do |opts|
    match do |actual|
      m = actual[:match][0]
      opts[:fns] == m[3][0]
    end
  end

  matcher :have_same_path do |opts|
    match do |actual|
      m = actual[:match][0]
      m[4] == opts[:path]
    end
  end

  matcher :have_same_handler do |data|
    match do |actual|
      actual[0] == data[0] &&
      actual[1] == data[1] &&
      actual[2][0] == data[2]
    end
  end
end
