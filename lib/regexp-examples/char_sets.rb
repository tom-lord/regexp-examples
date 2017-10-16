# :nodoc:
module RegexpExamples
  # Definitions of various special characters, used in regular expressions.
  # For example, `/\h/.examples` will return the value of `Hex` in this module
  module CharSets
    Lower        = Array('a'..'z')
    Upper        = Array('A'..'Z')
    Digit        = Array('0'..'9')
    Punct        = %w[! " # % & ' ( ) * , - . / : ; ? @ [ \\ ] _ { }] \
                     | (RUBY_VERSION >= '2.4.0' ? %w[$ + < = > ^ ` | ~] : [])
    Hex          = Array('a'..'f') | Array('A'..'F') | Digit
    Word         = Lower | Upper | Digit | ['_']
    Whitespace   = [' ', "\t", "\n", "\r", "\v", "\f"].freeze
    Control      = (0..31).map(&:chr) | ["\x7f"]
    # Ensure that the "common" characters appear first in the array
    # Also, ensure "\n" comes first, to make it obvious when included
    Any          = ["\n"] | Lower | Upper | Digit | Punct | (0..127).map(&:chr)
    AnyNoNewLine = Any - ["\n"]

    # Map of special regex characters, to their associated character sets
    BackslashCharMap = {
      'd' => CharSets::Digit,
      'D' => CharSets::Any - CharSets::Digit,
      'w' => CharSets::Word,
      'W' => CharSets::Any - CharSets::Word,
      's' => CharSets::Whitespace,
      'S' => CharSets::Any - CharSets::Whitespace,
      'h' => CharSets::Hex,
      'H' => CharSets::Any - CharSets::Hex,

      't' => ["\t"], # tab
      'n' => ["\n"], # new line
      'r' => ["\r"], # carriage return
      'f' => ["\f"], # form feed
      'a' => ["\a"], # alarm
      'v' => ["\v"], # vertical tab
      'e' => ["\e"], # escape
    }.freeze

    POSIXCharMap = {
      'alnum'  => CharSets::Upper | CharSets::Lower | CharSets::Digit,
      'alpha'  => CharSets::Upper | CharSets::Lower,
      'blank'  => [' ', "\t"],
      'cntrl'  => CharSets::Control,
      'digit'  => CharSets::Digit,
      'graph'  => (CharSets::Any - CharSets::Control) - [' '], #  Visible chars
      'lower'  => CharSets::Lower,
      'print'  => CharSets::Any - CharSets::Control,
      'punct'  => CharSets::Punct,
      'space'  => CharSets::Whitespace,
      'upper'  => CharSets::Upper,
      'xdigit' => CharSets::Hex,
      'word'   => CharSets::Word,
      'ascii'  => CharSets::Any
    }.freeze

    NamedPropertyCharMap = UnicodeCharRanges.new
  end.freeze
end
