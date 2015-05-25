require 'rspec/expectations'

module RestfulHelpers
  extend RSpec::Matchers::DSL

  matcher :regex_be_equal do |opts|
    match do |actual|

      m = actual[:match][0]

      regex = m[:regex] == match[0]
      vars  = m[:vars]  == match[1]    unless opts[:vars].nil?
      name  = m[:name]  == match[2]    unless opts[:name].nil?
      fns   = m[:fns]   == match[3][0] unless opts[:fns].nil?
      path  = m[:path]  == match[4]    unless opts[:path].nil?

      m && regex && vars && name && fns && path
    end
  end

  matcher :vars_be_equal do |opts|
    match do |actual|

      m = actual[:match][0]

      regex = m[:regex] == match[0]
      vars  = m[:vars]  == match[1]    unless opts[:vars].nil?
      name  = m[:name]  == match[2]    unless opts[:name].nil?
      fns   = m[:fns]   == match[3][0] unless opts[:fns].nil?
      path  = m[:path]  == match[4]    unless opts[:path].nil?

      m && regex && vars && name && fns && path
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
      binding.pry
      m = actual[:match][0][3]

      regex = m[:regex] == match[0]
      vars  = m[:vars]  == match[1]    unless opts[:vars].nil?
      name  = m[:name]  == match[2]    unless opts[:name].nil?
      fns   = m[:fns]   == match[3][0] unless opts[:fns].nil?
      path  = m[:path]  == match[4]    unless opts[:path].nil?

      m && regex && vars && name && fns && path
    end
  end

  matcher :have_same_path do |opts|
    match do |actual|
      m    = actual[:match][0]
      path = m[4] == opts[:path]
    end
  end
end
