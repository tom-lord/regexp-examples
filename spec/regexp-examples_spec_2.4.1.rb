RSpec.describe Regexp, '#examples' do
  def self.examples_raise_illegal_syntax_error(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        expect { regexp.examples }.to raise_error RegexpExamples::IllegalSyntaxError
      end
    end
  end
  context 'absent operator' do
    it 'treats the group as an empty match' do
      expect(/abc(?~def)ghi/.examples).to eq(['abcghi'])
    end
  end
end
