require_relative 'support/spec_helper'

context 'when testing a route that redirects' do
  it 'appears to have redirected' do
    get :redirect do |sim|
      expect(sim.redirected?).to eq(true)
    end
  end

  it 'appears to have redirected to a path' do
    get :redirect do |sim|
      expect(sim.redirected?(to: :default)).to eq(true)
    end
  end

  it 'exposes the type of redirect' do
    get :redirect do |sim|
      expect(sim.redirected?(as: :found)).to eq(true)
    end
  end
end
