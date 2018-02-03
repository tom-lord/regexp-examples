RSpec.describe Regexp, '#examples' do
  context 'absent operator' do
    it 'treats the group as an empty match' do
      expect(/abc(?~def)ghi/.examples).to eq(['abcghi'])
    end
  end
end
