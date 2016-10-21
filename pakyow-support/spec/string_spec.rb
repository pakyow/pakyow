require 'pakyow/support/string'

RSpec.describe String do
  describe 'remove_route_vars' do
    it 'removes route vars' do
      expect(String.remove_route_vars('/:id')).to eq('/')
      expect(String.remove_route_vars('/bret')).to eq('/bret')
      expect(String.remove_route_vars('/bret/')).to eq('/bret')
      expect(String.remove_route_vars('/bret/:id')).to eq('/bret')
      expect(String.remove_route_vars(':id0/bret/:id')).to eq('bret')
      expect(String.remove_route_vars(':id0/:id1/bret/:id')).to eq('bret')
      expect(String.remove_route_vars('/bret/:id/:id')).to eq('/bret')
      expect(String.remove_route_vars('/fred/:id/barney')).to eq('/fred/barney')
      expect(String.remove_route_vars('/fred/:fred_id/barney/:barney_id')).to eq('/fred/barney')
      expect(String.remove_route_vars('/fred/:_id/barney/:id')).to eq('/fred/barney')
      expect(String.remove_route_vars('/fred/:id/:id2/barney')).to eq('/fred/barney')
      expect(String.remove_route_vars('/fred//barney')).to eq('/fred//barney')
    end
  end

  describe 'split_at_last_dot' do
    it 'splits at last dot' do
      expect(String.split_at_last_dot('one')).to eq(['one', nil])
      expect(String.split_at_last_dot('one.')).to eq(['one', ''])
      expect(String.split_at_last_dot('.one')).to eq(['', 'one'])
      expect(String.split_at_last_dot('./one')).to eq(['', '/one'])
      expect(String.split_at_last_dot('one/two.x/three.four')).to eq(['one/two.x/three', 'four'])
      expect(String.split_at_last_dot('one/two.x/three')).to eq(['one/two', 'x/three'])
      expect(String.split_at_last_dot('one.two.three')).to eq(['one.two', 'three'])
    end

    it 'is accurate on windows' do
      expect(String.parse_path_from_caller("C:/test/test_application.rb:5")).to eq('C:/test/test_application.rb')
    end
  end
end

