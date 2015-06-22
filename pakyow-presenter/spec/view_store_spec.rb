require_relative 'support/helper'

describe Pakyow::Presenter::ViewStore do
  before do
    @store = Pakyow::Presenter::ViewStore.new(VIEW_PATH)
  end

  it 'finds path at file' do
    expect(@store.at?('sub')).to eq true
    expect(@store.at?('sub/')).to eq true
    expect(@store.at?('/sub')).to eq true
    expect(@store.at?('/sub/')).to eq true
  end

  it 'finds path at dir' do
    expect(@store.at?('sub_dir')).to eq true
    expect(@store.at?('sub_dir/')).to eq true
    expect(@store.at?('/sub_dir')).to eq true
    expect(@store.at?('/sub_dir/')).to eq true
  end

  it 'does not find undefined paths' do
    expect(@store.at?('missing')).to be false
    expect(@store.at?('missing/')).to be false
    expect(@store.at?('/missing')).to be false
    expect(@store.at?('/missing/')).to be false
  end

  it 'uses default template' do
    expect(:default).to eq @store.template('/').name
    expect(:default).to eq @store.template('').name

    expect(:default).to eq @store.template('pageless').name
    expect(:default).to eq @store.template('/pageless').name
    expect(:default).to eq @store.template('pageless/').name
    expect(:default).to eq @store.template('/pageless/').name
  end

  it 'uses page specified template' do
    expect(:sub).to eq @store.template('sub').name
  end

  it 'uses page specified title' do
    expect('custom title').to eq @store.view('title').title
  end

  it 'template title not reset when no title specified' do
    expect('pakyow').to eq @store.view('no_title').title
  end

  it 'fails when no template' do
    skip 'TODO rewrite since loading views fails when no template'
    #expect(@store.template('no_template')).to raise_error StandardError
  end

  it 'uses default page content' do
    expect('index').to eq str_to_doc(@store.view('/').to_html).css('body').children.to_html.strip
  end

  it 'uses named page content' do
    expect('multi side').to eq str_to_doc(@store.view('multi').to_html).css('body').children.to_html.strip
  end

  it 'falls back when no page' do
    expect('index').to eq str_to_doc(@store.view("no_page").to_html).css('body').inner_text.strip
  end

  it 'includes partial at current path' do
    expect('partial1').to eq str_to_doc(@store.view('/partial').to_html).css('body').children.to_html.strip
  end

  it 'test partials can be overridden' do
    expect('partial1.1').to eq str_to_doc(@store.view('/partial/override').to_html).css('body').children.to_html.strip
  end

  it 'partials include other partials' do
    expect('partial2').to eq str_to_doc(@store.view('/partial/inception').to_html).css('body').children.to_html.strip
  end

  it 'template includes partials' do
    expect('partial1').to eq str_to_doc(@store.view('/partial/template').to_html).css('body').children.to_html.strip
  end

  it 'template_is_retrievable_by_name' do
    template = @store.template(:multi)
    expect('multi').to eq str_to_doc(template.to_html).css('title').inner_html.strip
  end

  it 'partial can be retrieved for path' do
    name = :partial1
    partial = @store.partial('/', name)
    expect('partial1').to eq partial.to_html.strip
  end

  it  'partials can be included multiple times' do
    expect("partial1partial1").to eq str_to_doc(@store.view('/partial/multiple').to_html).css('body').inner_text.strip.gsub("\n", '')
  end

  it 'view building does not modify template' do
    html = @store.template('/').to_html
    @store.view('/')

    expect(html).to eq @store.template('/').to_html
  end

  it 'iterates_over_views' do
    @store.views do |view, path|
      expect(view).to be_a Pakyow::Presenter::View
    end
  end

  it 'ignores dotfiles' do
    expect { @store.template('.vimswap.swp') }.to raise_error Pakyow::Presenter::MissingView
  end
end
