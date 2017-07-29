RSpec.describe Regexp, '#examples' do
  def self.examples_exist_and_match(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        regexp_examples = regexp.examples(max_group_results: 99_999)
        examples_exist(regexp, regexp_examples)
        examples_match(regexp, regexp_examples)
      end
    end
  end

  def self.examples_raise_illegal_syntax_error(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        expect { regexp.examples }.to raise_error RegexpExamples::IllegalSyntaxError
      end
    end
  end

  def self.examples_are_empty(*regexps)
    regexps.each do |regexp|
      it "examples for /#{regexp.source}/" do
        expect(regexp.examples).to be_empty
      end
    end
  end

  context 'returns matching strings' do
    context 'for basic repeaters' do
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

    context 'for basic groups' do
      examples_exist_and_match(
        /[a]/,
        /(a)/,
        /a|b/,
        /./
      )
    end

    context 'for complex char groups (square brackets)' do
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
        /[-abc]/,
        /[abc-]/,
        /[%-+]/, # This regex is "supposed to" match some surprising things!!!
        /['-.]/, # Test to ensure no "infinite loop" on character set expansion
        /[[abc]]/, # Nested groups
        /[[[[abc]]]]/,
        /[[a][b][c]]/,
        /[[a-h]&&[f-z]]/, # Set intersection
        /[[a-h]&&ab[c]]/, # Set intersection
        /[[a-h]&[f-z]]/, # NOT set intersection
      )
    end

    context 'for complex multi groups' do
      examples_exist_and_match(
        /(normal)/,
        /(?:nocapture)/,
        /(?<name>namedgroup)/,
        /(?<name>namedgroup) \k<name>/,
        /(?<name>namedgroup) \k'name'/
      )
    end

    context 'for escaped characters' do
      all_letters = Array('a'..'z') | Array('A'..'Z')
      special_letters = %w(b c g p u x z A B C G M P Z)
      valid_letters = all_letters - special_letters

      valid_letters.each do |char|
        backslash_char = "\\#{char}"
        examples_exist_and_match(/#{backslash_char}/)
      end
      examples_exist_and_match(/[\b]/)
    end

    context 'for backreferences' do
      examples_exist_and_match(
        /(repeat) \1/,
        /(ref1) (ref2) \1 \2/,
        /((ref2)ref1) \1 \2/,
        /((ref1and2)) \1 \2/,
        /(1)(2)(3)(4)(5)(6)(7)(8)(9)(10) \10\9\8\7\6\5\4\3\2\1/,
        /(a?(b?(c?(d?(e?)))))/,
        /(a)? \1/,
        /(a|(b)) \2/,
        /([ab]){2} \1/, # \1 should always be the LAST result of the capture group
        /(ref1) (ref2) \k'1' \k<-1>/, # RELATIVE backref!
      )
    end

    context 'for escaped octal characters' do
      examples_exist_and_match(
        /\10\20\30\40\50/,
        /\00\07\100\177/,
        /\177123/ # Should work for numbers up to 177
      )
    end

    context 'for complex patterns' do
      # Longer combinations of the above
      examples_exist_and_match(
        %r{https?://(www\.)github\.com},
        /(I(N(C(E(P(T(I(O(N)))))))))*/,
        /[\w]{1}/,
        /((a?b*c+)) \1/,
        /((a?b*c+)?) \1/,
        /a|b|c|d/,
        /a+|b*|c?/,
        /one|two|three/
      )
    end

    context 'for illegal syntax' do
      examples_raise_illegal_syntax_error(
        /(?=lookahead)/,
        /(?!neglookahead)/,
        /(?<=lookbehind)/,
        /(?<!neglookbehind)/,
        /\bword-boundary/,
        /no\Bn-word-boundary/,
        /start-of\A-string/,
        /start-of^-line/,
        /end-of\Z-string/,
        /end-of\z-string/,
        /end-of$-line/,
        /(?<name> ... \g<name>*)/
      )
    end

    context 'ignore start/end anchors if at start/end' do
      examples_exist_and_match(
        /\Astart/,
        /\Glast-match/,
        /^start/,
        /end$/,
        /end\z/
        # Cannot test /end\Z/ with the generic method here,
        # as it's a special case. Tested specially below.
      )
    end

    context 'for named properties' do
      examples_exist_and_match(
        /\p{AlPhA}/, # Case insensitivity
        /\p{^Ll}/, # Negation syntax type 1
        /\P{Ll}/, # Negation syntax type 2
        /\P{^Ll}/ # Double negation!! (Should cancel out)
      )
      # An exhaustive set of tests for all named properties!!! This is useful
      # for verifying the PStore contains correct values for all ruby versions
      %w(
        Alnum Alpha Blank Cntrl Digit Graph Lower Print Punct Space Upper XDigit
        Word ASCII Any Assigned L Ll Lm Lo Lt Lu M Mn Mc Me N Nd Nl No P Pc Pd
        Ps Pe Pi Pf Po S Sm Sc Sk So Z Zs Zl Zp C Cc Cf Cn Co Arabic Armenian
        Balinese Bengali Bopomofo Braille Buginese Buhid Canadian_Aboriginal
        Cham Cherokee Common Coptic Cyrillic Devanagari Ethiopic Georgian
        Glagolitic Greek Gujarati Gurmukhi Han Hangul Hanunoo Hebrew Hiragana
        Inherited Kannada Katakana Kayah_Li Khmer Lao Latin Lepcha Limbu Malayalam
        Mongolian Myanmar New_Tai_Lue Nko Ogham Ol_Chiki Oriya Phags_Pa Rejang
        Runic Saurashtra Sinhala Sundanese Syloti_Nagri Syriac Tagalog Tagbanwa
        Tai_Le Tamil Telugu Thaana Thai Tibetan Tifinagh Vai Yi
      ).each do |property|
        it "examples for /\p{#{property}}/" do
          regexp_examples = /\p{#{property}}/.examples(max_group_results: 99_999)
          expect(regexp_examples)
            .not_to be_empty,
                    "No examples were generated for regexp: /\p{#{property}}/"
          # Just do one big check, for test system performance (~30% faster)
          # (Otherwise, we're doing up to 128 checks on 123 properties!!!)
          expect(regexp_examples.join('')).to match(/\A\p{#{property}}+\z/)
        end
      end

      # The following seem to genuinely have no matching examples (!!??!!?!)
      %w(
        Cs Carian Cuneiform Cypriot Deseret Gothic Kharoshthi Linear_B Lycian
        Lydian Old_Italic Old_Persian Osmanya Phoenician Shavian Ugaritic
      ).each do |property|
        examples_are_empty(/\p{#{property}}/)
      end
    end

    context 'for control characters' do
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

    context 'for escape sequences' do
      examples_exist_and_match(
        /\x42/,
        /\x1D/,
        /\x3word/,
        /#{"\x80".force_encoding("ASCII-8BIT")}/
      )
    end

    context 'for unicode sequences' do
      examples_exist_and_match(
        /\u6829/,
        /\uabcd/,
        /\u{42}word/
      )
    end

    context 'for empty character sets' do
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

    context 'for comment groups' do
      examples_exist_and_match(
        /a(?#comment)b/,
        /a(?#ugly backslashy\ comment\\\))b/
      )
    end

    context 'for POSIX groups' do
      examples_exist_and_match(
        /[[:alnum:]]/,
        /[[:alpha:]]/,
        /[[:blank:]]/,
        /[[:cntrl:]]/,
        /[[:digit:]]/,
        /[[:graph:]]/,
        /[[:lower:]]/,
        /[[:print:]]/,
        /[[:punct:]]/,
        /[[:space:]]/,
        /[[:upper:]]/,
        /[[:xdigit:]]/,
        /[[:word:]]/,
        /[[:ascii:]]/,
        /[[:^alnum:]]/ # Negated
      )
    end

    context 'exact examples match' do
      # More rigorous tests to assert that ALL examples are being listed
      context 'default config options' do
        # Simple examples
        it { expect(/[ab]{2}/.examples).to match_array %w(aa ab ba bb) }
        it { expect(/(a|b){2}/.examples).to match_array %w(aa ab ba bb) }
        it { expect(/a+|b?/.examples).to match_array ['a', 'aa', 'aaa', '', 'b'] }

        # Only display unique examples:
        it { expect(/a|a|b|b/.examples).to match_array %w(a b) }
        it { expect(/[ccdd]/.examples).to match_array %w(c d) }

        # a{1}? should be equivalent to (?:a{1})?, i.e. NOT a "non-greedy quantifier"
        it { expect(/a{1}?/.examples).to match_array ['', 'a'] }
      end

      context 'end of string' do
        it { expect(/test\z/.examples).to match_array %w(test) }
        it { expect(/test\Z/.examples).to match_array ['test', "test\n"] }
      end

      context 'backreferences and escaped octal combined' do
        it do
          expect(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)? \10\9\8\7\6\5\4\3\2\1/.examples)
            .to match_array ["abcdefghi \x08ihgfedcba", 'abcdefghij jihgfedcba']
        end
      end

      context 'case insensitive' do
        it { expect(/ab/i.examples).to match_array %w(ab aB Ab AB) }
        it do
          expect(/a+/i.examples)
            .to match_array %w(a A aa aA Aa AA aaa aaA aAa aAA Aaa AaA AAa AAA)
        end
        it { expect(/([ab])\1/i.examples).to match_array %w(aa bb AA BB) }
      end

      context 'multiline' do
        it { expect(/./.examples(max_group_results: 999)).not_to include "\n" }
        it { expect(/./m.examples(max_group_results: 999)).to include "\n" }
      end

      context 'exteded form' do
        it { expect(/a b c/x.examples).to eq %w(abc) }
        it { expect(/a#comment/x.examples).to eq %w(a) }
        it do
          expect(
            /
              line1 #comment
              line2 #comment
            /x.examples
          ).to eq %w(line1line2)
        end
      end

      context 'options toggling' do
        context 'rest of string' do
          it { expect(/a(?i)b(?-i)c/.examples).to match_array %w(abc aBc) }
          it { expect(/a(?x)   b(?-x) c/.examples).to eq %w(ab\ c) }
          it { expect(/(?m)./.examples(max_group_results: 999)).to include "\n" }
          # Toggle "groups" should not increase backref group count:
          it { expect(/(?i)(a)-\1/.examples).to match_array %w(a-a A-A) }
        end
        context 'subexpression' do
          it { expect(/a(?i:b)c/.examples).to match_array %w(abc aBc) }
          it { expect(/a(?i:b(?-i:c))/.examples).to match_array %w(abc aBc) }
          it { expect(/a(?-i:b)c/i.examples).to match_array %w(abc abC Abc AbC) }
        end
      end
    end # context 'exact examples match'
  end # context 'returns matching strings'
end
