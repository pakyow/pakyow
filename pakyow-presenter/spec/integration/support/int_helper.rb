require_relative '../../spec_helper'

Dir[File.join(File.dirname(__FILE__), 'helpers', '*.rb')].each {|file| require file }
Dir[File.join(File.dirname(__FILE__), 'mixins', '*.rb')].each {|file| require file }

require_relative 'test_app'
include ViewBindingHelpers

def str_to_doc(str)
  if str.match(/<html.*>/)
    Nokogiri::HTML::Document.parse(str)
  else
    Nokogiri::HTML.fragment(str)
  end
end

def reset_index_contents
  file = File.join(VIEW_PATH, 'index.html')
  contents = File.read(file)
  File.open(file, 'w') { |file| file.write('index') } unless contents == 'index'
end

$views = {}

$views[:many] = create_view_from_string(<<-D)
  <div class="contact" data-scope="contact">
    <span data-prop="full_name">John Doe</span>
    <a data-prop="email">john@example.com</a>
  </div>
  <div class="contact" data-scope="contact">
    <span data-prop="full_name">John Doe</span>
    <a data-prop="email">john@example.com</a>
  </div>
  <div class="contact" data-scope="contact">
    <span data-prop="full_name">John Doe</span>
    <a data-prop="email">john@example.com</a>
  </div>
D

$views[:single] = create_view_from_string(<<-D)
  <div class="contact" data-scope="contact">
    <span data-prop="full_name">John Doe</span>
    <a data-prop="email">john@example.com</a>
  </div>
D

$views[:unscoped] = create_view_from_string(<<-D)
  <span class="foo" data-prop="foo"></span>
D

