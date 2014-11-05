describe Regexp, "#examples" do
  def examples_exist_and_match(*regexps)
    regexps.each do |regexp|
      expect(regexp.examples).not_to be_empty
      regexp.examples.each { |example| expect(example).to match(regexp) }
    end
  end

  context 'returns matching strings' do
    it "for basic repeaters" do
      examples_exist_and_match(
        /a/,
        /a*/,
        /a+/,
        /a?/,
        /a{1}/,
        /a{1,}/,
        /a{1,2}/
      )
    end

    it "for basic groups" do
      examples_exist_and_match(
        /[a]/,
        /(a)/,
        /a|b/,
        /./
      )
    end

    it "for complex char groups (square brackets)" do
      examples_exist_and_match(
        /[abc]/,
        /[a-c]/,
        /[abc-e]/,
        /[^a-zA-Z]/
      )
    end

    it "for escaped characters" do
      examples_exist_and_match(
        /\w/,
        /\s/,
        /\d/,
        /\t/,
        /\n/,
        /\f/,
        /\a/,
        /\v/,
        /\e/
      )
    end

    it "for backreferences" do
      examples_exist_and_match(
        /(repeat) \1/,
        /(ref1) (ref2) \1 \2/,
        /((ref2)ref1) \1 \2/,
        /((ref1and2)) \1 \2/
      )
    end

    it "for complex patterns" do
      # Longer combinations of the above
      examples_exist_and_match(
        /https?:\/\/(www\.)github\.com/,
        /(I(N(C(E(P(T(I(O(N)))))))))*/,
        /[\w]{1}/,
        /((a?b*c+)?) \1/
      )
    end
  end
end
