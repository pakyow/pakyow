require_relative 'support/int_helper'

RSpec.describe Pakyow::Presenter::View do
  describe 'with StringDoc' do
    before do
      Pakyow::Config.presenter.view_doc_class = Pakyow::Presenter::StringDoc
    end

    include_examples :form_binding_specs
  end
end
