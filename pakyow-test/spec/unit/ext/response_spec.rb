require_relative '../../../lib/test_help/ext/response'

describe Pakyow::Response do
  describe 'status' do
    it 'returns a mock status with value' do
      r = Pakyow::Response.new({})
      r.status = 200

      expect(r.status).to be_an_instance_of(Pakyow::TestHelp::MockStatus)
      expect(r.status.value).to eq(200)
    end
  end
end
