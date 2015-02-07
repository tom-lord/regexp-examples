RSpec.describe Regexp, "#examples" do
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

  def self.examples_raise_illegal_syntax_error(*regexps)
    regexps.each do |regexp|
      it do
        expect{regexp.examples}.to raise_error RegexpExamples::IllegalSyntaxError
      end
    end
  end

  def self.examples_raise_unsupported_syntax_error(*regexps)
    regexps.each do |regexp|
      it do
        expect{regexp.examples}.to raise_error RegexpExamples::UnsupportedSyntaxError
      end
    end
  end

  def self.examples_are_empty(*regexps)
    regexps.each do |regexp|
      it do
        expect(regexp.examples).to be_empty
      end
    end
  end

  context 'returns matching strings' do
    context "for basic repeaters" do
      examples_exist_and_match(
        /a/,   # "one-time repeater"
        /a*/,  # greedy
        /a*?/, # reluctant (non-greedy)
        /a*+/, # possesive
        /a+/,
        /a+?/,
        /a*+/,
        /a?/,
        /a??/,
        /a?+/,
        /a{1}/,
        /a{1}?/,
        /a{1}+/,
        /a{1,}/,
        /a{1,}?/,
        /a{1,}+/,
        /a{,2}/,
        /a{,2}?/,
        /a{,2}+/,
        /a{1,2}/,
        /a{1,2}?/,
        /a{1,2}+/
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
        /[%-+]/, # This regex is "supposed to" match some surprising things!!!
        /['-.]/ # Test to ensure no "infinite loop" on character set expansion
      )
    end

    context "for complex multi groups" do
      examples_exist_and_match(
        /(normal)/,
        /(?:nocapture)/,
        /(?<name>namedgroup)/,
        /(?<name>namedgroup) \k<name>/
      )
    end

    context "for escaped characters" do
      examples_exist_and_match(
        /\w/,
        /\W/,
        /\s/,
        /\S/,
        /\d/,
        /\D/,
        /\h/,
        /\H/,
        /\t/,
        /\n/,
        /\f/,
        /\a/,
        /\v/,
        /\e/,
        /[\b]/
      )
    end

    context "for backreferences" do
      examples_exist_and_match(
        /(repeat) \1/,
        /(ref1) (ref2) \1 \2/,
        /((ref2)ref1) \1 \2/,
        /((ref1and2)) \1 \2/,
        /(one)(two)(three)(four)(five)(six)(seven)(eight)(nine)(ten) \10\9\8\7\6\5\4\3\2\1/,
        /(a?(b?(c?(d?(e?)))))/,
        /(a)? \1/,
        /(a|(b)) \2/,
        /([ab]){2} \1/ # \1 should always be the LAST result of the capture group
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
        /a+|b*|c?/,
        /one|two|three/
      )
    end

    context "for illegal syntax" do
      examples_raise_illegal_syntax_error(
        /(?=lookahead)/,
        /(?!neglookahead)/,
        /(?<=lookbehind)/,
        /(?<!neglookbehind)/,
        /\bword-boundary/,
        /no\Bn-word-boundary/,
        /\Glast-match/,
        /start-of\A-string/,
        /start-of^-line/,
        /end-of\Z-string/,
        /end-of\z-string/,
        /end-of$-line/
      )
    end

    context "ignore start/end anchors if at start/end" do
      examples_exist_and_match(
        /\Astart/,
        /^start/,
        /end$/,
        /end\z/,
        /end\Z/
      )
    end

    context "for unsupported syntax" do
      examples_raise_unsupported_syntax_error(
        /\p{L}/,
        /\p{Arabic}/,
        /\p{^Ll}/,
        /(?<name> ... \g<name>*)/,
        /[[:space:]]/
      )
    end

    context "for control characters" do
      examples_exist_and_match(
        /\ca/,
        /\cZ/,
        /\c9/,
        /\c[/,
        /\c#/,
        /\c?/,
        /\C-a/,
        /\C-&/
      )
    end

    context "for escape sequences" do
      examples_exist_and_match(
        /\x42/,
        /\x1D/,
        /\x3word/,
        /#{"\x80".force_encoding("ASCII-8BIT")}/
      )
    end

    context "for unicode sequences" do
      examples_exist_and_match(
      /\u6829/,
      /\uabcd/,
      /\u{42}word/
      )
    end

    context "for empty character sets" do
      examples_are_empty(
        /[^\d\D]/,
        /[^\w\W]/,
        /[^\s\S]/,
        /[^\h\H]/,
        /[^\D0-9]/,
        /[^\Wa-zA-Z0-9_]/,
        /[^\d\D]+/,
        /[^\d\D]{2}/,
        /[^\d\D]word/
      )
    end

    context "exact examples match" do
      # More rigorous tests to assert that ALL examples are being listed
      context "default options" do
        # Simple examples
        it { expect(/[ab]{2}/.examples).to eq ["aa", "ab", "ba", "bb"] }
        it { expect(/(a|b){2}/.examples).to eq ["aa", "ab", "ba", "bb"] }
        it { expect(/a+|b?/.examples).to eq ["a", "aa", "aaa", "", "b"] }

        # a{1}? should be equivalent to (?:a{1})?, i.e. NOT a "non-greedy quantifier"
        it { expect(/a{1}?/.examples).to eq ["", "a"] }
      end

      context "max_repeater_variance option" do
        it do
          expect(/a+/.examples(max_repeater_variance: 5))
            .to eq %w(a aa aaa aaaa aaaaa aaaaaa)
        end
        it do
          expect(/a{4,8}/.examples(max_repeater_variance: 0))
            .to eq %w(aaaa)
        end
      end

      context "max_group_results option" do
        it do
          expect(/\d/.examples(max_group_results: 10))
            .to eq %w(0 1 2 3 4 5 6 7 8 9)
        end
      end

      context "case insensitive" do
        it { expect(/ab/i.examples).to eq %w(ab aB Ab AB) }
        it { expect(/a+/i.examples).to eq %w(a A aa aA Aa AA aaa aaA aAa aAA Aaa AaA AAa AAA) }
        it { expect(/([ab])\1/i.examples).to eq %w(aa bb AA BB) }
      end

      context "multiline" do
        it { expect(/./.examples(max_group_results: 999)).not_to include "\n" }
        it { expect(/./m.examples(max_group_results: 999)).to include "\n" }
      end
    end

  end
end
