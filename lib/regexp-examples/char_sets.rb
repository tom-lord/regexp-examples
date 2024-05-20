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
      'd' => Digit,
      'D' => Any - Digit,
      'w' => Word,
      'W' => Any - Word,
      's' => Whitespace,
      'S' => Any - Whitespace,
      'h' => Hex,
      'H' => Any - Hex,

      't' => ["\t"], # tab
      'n' => ["\n"], # new line
      'r' => ["\r"], # carriage return
      'f' => ["\f"], # form feed
      'a' => ["\a"], # alarm
      'v' => ["\v"], # vertical tab
      'e' => ["\e"], # escape
    }.freeze

    POSIXCharMap = {
      'alnum'  => Upper | Lower | Digit,
      'alpha'  => Upper | Lower,
      'blank'  => [' ', "\t"],
      'cntrl'  => Control,
      'digit'  => Digit,
      'graph'  => (Any - Control) - [' '], #  Visible chars
      'lower'  => Lower,
      'print'  => Any - Control,
      'punct'  => Punct,
      'space'  => Whitespace,
      'upper'  => Upper,
      'xdigit' => Hex,
      'word'   => Word,
      'ascii'  => Any
    }.freeze
  end.freeze
end
