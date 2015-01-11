describe Regexp, "#examples" do
  def self.examples_exist_and_match(*regexps)
    regexps.each do |regexp|
      it do
        regexp_examples = regexp.examples
        expect(regexp_examples).not_to be_empty
        regexp_examples.each { |example| expect(example).to match(/\A(?:#{regexp.source})\z/) }
        # Note: /\A...\z/ is used, to prevent misleading examples from passing the test.
        # For example, we don't want things like:
        # /a*/.examples to include "xyz"
        # /a|b/.examples to include "bad"
      end
    end
  end

  context 'returns matching strings' do
    context "for basic repeaters" do
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

    context "for basic groups" do
      examples_exist_and_match(
        /[a]/,
        /(a)/,
        /a|b/,
        /./
      )
    end

    context "for complex char groups (square brackets)" do
      examples_exist_and_match(
        /[abc]/,
        /[a-c]/,
        /[abc-e]/,
        /[^a-zA-Z]/,
        /[\w]/,
        /[]]/, # TODO: How to suppress annoying warnings on this test?
        /[\]]/,
        /[\\]/,
        /[\\\]]/,
        /[\n-\r]/,
        /[\-]/,
        /[%-+]/ # This regex is "supposed to" match some surprising things!!!
      )
    end

    context "for escaped characters" do
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

    context "for backreferences" do
      examples_exist_and_match(
        /(repeat) \1/,
        /(ref1) (ref2) \1 \2/,
        /((ref2)ref1) \1 \2/,
        /((ref1and2)) \1 \2/
      )
    end

    context "for complex patterns" do
      # Longer combinations of the above
      examples_exist_and_match(
        /https?:\/\/(www\.)github\.com/,
        /(I(N(C(E(P(T(I(O(N)))))))))*/,
        /[\w]{1}/,
        /((a?b*c+)) \1/,
        /((a?b*c+)?) \1/,
        /a|b|c|d/,
        /a+|b*|c?/
      )
    end
  end
end
