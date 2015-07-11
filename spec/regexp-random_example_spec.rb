RSpec.describe Regexp, "#random_example" do
  def self.random_example_matches(*regexps)
    regexps.each do |regexp|
      it "random example for /#{regexp.source}/" do
        random_example = regexp.random_example

        expect(random_example).to be_a String # Not an Array!
        expect(random_example).to match(Regexp.new("\\A(?:#{regexp.source})\\z", regexp.options))
      end
    end
  end

  context "smoke tests" do
    # Just a few "smoke tests", to ensure the basic method isn't broken.
    # Testing of the RegexpExamples::Parser class is all covered by Regexp#examples test already.
    random_example_matches(
      /\w{10}/,
      /(we(need(to(go(deeper)?)?)?)?) \1/,
      /case insensitive/i,
      /front seat|back seat/, # Which seat will I take??
    )
  end
end
