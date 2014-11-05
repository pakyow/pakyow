require 'rubygems'
require 'rspec'
require 'pry'
require 'pp'

require File.expand_path('../../../../pakyow-support/lib/pakyow-support', __FILE__)
require File.expand_path('../../../../pakyow-core/lib/pakyow-core', __FILE__)
require File.expand_path('../../../lib/pakyow-presenter', __FILE__)

require 'support/mixins/doc_specs'
require 'support/mixins/view_scope_specs'
require 'support/mixins/attr_specs'
require 'support/mixins/form_binding_specs'
require 'support/mixins/view_repeating_specs'
require 'support/mixins/view_matching_specs'
require 'support/mixins/view_building_specs'

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  Pakyow.configure_logger
  begin
    yield
  ensure
    $stdout = original_stdout
    Pakyow.configure_logger
  end
  fake.string
end
