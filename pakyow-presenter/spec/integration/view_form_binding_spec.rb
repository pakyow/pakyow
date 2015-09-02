require_relative 'support/int_helper'

describe Pakyow::Presenter::View do
  describe 'with NokogiriDoc' do
    before do
      Pakyow::Config.presenter.view_doc_class = Pakyow::Presenter::NokogiriDoc
    end

    include_examples :form_binding_specs
  end

  describe 'with StringDoc' do
    before do
      Pakyow::Config.presenter.view_doc_class = Pakyow::Presenter::StringDoc
    end

    include_examples :form_binding_specs
  end
end
