require_relative '../../lib/test_help/simulation'

describe Pakyow::TestHelp::Simulation do
  let :app do
    instance_double('App', request: request, response: response, req: request, res: response)
  end

  let :request do
    instance_double('Request')
  end

  let :response do
    instance_double('Response', status: status, type: type, format: format, headers: headers)
  end

  let :status do
    200
  end

  let :type do
    'text/html'
  end

  let :format do
    :html
  end

  let :headers do
    { 'Location' => '/redirected' }
  end

  let :simulation do
    Pakyow::TestHelp::Simulation.new(app)
  end

  it 'makes app available with public reader' do
    expect(simulation.app).to eq(app)
  end

  describe 'delegation' do
    it "returns app's request" do
      expect(simulation.request).to eq(app.request)
    end

    it "returns app's response" do
      expect(simulation.response).to eq(app.response)
    end

    it "returns response's status" do
      expect(simulation.status).to eq(response.status)
    end

    it "returns response's type" do
      expect(simulation.type).to eq(response.type)
    end

    it "returns response's format" do
      expect(simulation.format).to eq(response.format)
    end
  end

  describe 'redirected?' do
    context 'when response does not have a redirect status' do
      it 'returns false' do
        expect(simulation.redirected?).to eq(false)
      end
    end

    context 'when response does not have a location header' do
      let :headers do
        {}
      end

      it 'returns false' do
        expect(simulation.redirected?).to eq(false)
      end
    end

    context 'when response has a location header' do
      context 'when request was redirected as 301' do
        let :status do
          301
        end

        it 'returns true' do
          expect(simulation.redirected?).to eq(true)
        end

        context 'testing for redirection type' do
          context 'and the type does not match' do
            it 'returns false' do
              expect(simulation.redirected?(as: 302)).to eq(false)
            end
          end

          context 'and the type matches' do
            it 'returns true' do
              expect(simulation.redirected?(as: 301)).to eq(true)
            end
          end
        end
      end

      context 'when request was redirected as 302' do
        let :status do
          302
        end

        it 'returns true' do
          expect(simulation.redirected?).to eq(true)
        end

        context 'testing for redirection type' do
          context 'and the type does not match' do
            it 'returns false' do
              expect(simulation.redirected?(as: 307)).to eq(false)
            end
          end

          context 'and the type matches' do
            it 'returns true' do
              expect(simulation.redirected?(as: 302)).to eq(true)
            end
          end
        end
      end

      context 'when request was redirected as 307' do
        let :status do
          307
        end

        it 'returns true' do
          expect(simulation.redirected?).to eq(true)
        end

        context 'testing for redirection type' do
          context 'and the type does not match' do
            it 'returns false' do
              expect(simulation.redirected?(as: 301)).to eq(false)
            end
          end

          context 'and the type matches' do
            it 'returns true' do
              expect(simulation.redirected?(as: 307)).to eq(true)
            end
          end
        end
      end

      context 'when request has some redirect status' do
        let :status do
          Pakyow::TestHelp::Simulation::REDIRECT_STATUSES.sample
        end

        context 'testing for redirect location' do
          context 'and the location does not match' do
            it 'returns false' do
              expect(simulation.redirected?(to: '/foo')).to eq(false)
            end
          end

          context 'and the location matches' do
            it 'returns true' do
              expect(simulation.redirected?(to: '/redirected')).to eq(true)
            end
          end
        end
      end
    end
  end

  describe 'rerouted?' do
    context 'and the request was not rerouted' do
      before do
        allow(request).to receive(:first_path).and_return('/one')
        allow(request).to receive(:path).and_return('/one')
      end

      it 'returns false' do
        expect(simulation.rerouted?).to eq(false)
      end
    end

    context 'and the request was rerouted' do
      before do
        allow(request).to receive(:first_path).and_return('/one')
        allow(request).to receive(:path).and_return('/two')
      end

      it 'returns true' do
        expect(simulation.rerouted?).to eq(true)
      end

      context 'testing for reroute location' do
        context 'and the location does not match' do
          before do
            allow(request).to receive(:first_path).and_return('/one')
            allow(request).to receive(:path).and_return('/two')
          end

          it 'returns false' do
            expect(simulation.rerouted?(to: '/one')).to eq(false)
          end
        end

        context 'and the location matches' do
          before do
            allow(request).to receive(:first_path).and_return('/one')
            allow(request).to receive(:path).and_return('/two')
          end

          it 'returns false' do
            expect(simulation.rerouted?(to: '/two')).to eq(true)
          end
        end
      end
    end
  end
end
