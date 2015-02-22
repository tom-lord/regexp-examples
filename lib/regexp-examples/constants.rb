module RegexpExamples
  class ResultCountLimiters
    # The maximum variance for any given repeater, to prevent a huge/infinite number of
    # examples from being listed. For example, if @@max_repeater_variance = 2 then:
    # .* is equivalent to .{0,2}
    # .+ is equivalent to .{1,3}
    # .{2,} is equivalent to .{2,4}
    # .{,3} is equivalent to .{0,2}
    # .{3,8} is equivalent to .{3,5}
    MaxRepeaterVarianceDefault = 2

    # Maximum number of characters returned from a char set, to reduce output spam
    # For example, if @@max_group_results = 5 then:
    # \d = ["0", "1", "2", "3", "4"]
    # \w = ["a", "b", "c", "d", "e"]
    MaxGroupResultsDefault = 5

    class << self
      attr_reader :max_repeater_variance, :max_group_results
      def configure!(max_repeater_variance, max_group_results)
        @max_repeater_variance = (max_repeater_variance || MaxRepeaterVarianceDefault)
        @max_group_results = (max_group_results || MaxGroupResultsDefault)
      end
    end
  end

  def self.MaxRepeaterVariance
    ResultCountLimiters.max_repeater_variance
  end
  def self.MaxGroupResults
    ResultCountLimiters.max_group_results
  end

  module CharSets
    Lower      = Array('a'..'z')
    Upper      = Array('A'..'Z')
    Digit      = Array('0'..'9')
    Punct      = [33..47, 58..64, 91..96, 123..126].map { |r| r.map(&:chr) }.flatten
    Hex        = Array('a'..'f') | Array('A'..'F') | Digit
    Word       = Lower | Upper | Digit | ['_']
    Whitespace = [' ', "\t", "\n", "\r", "\v", "\f"]
    # Ensure that the "common" characters appear first in the array. Do not include "\n"!
    Any        = Lower | Upper | Digit | Punct | (0..255).map(&:chr) - ["\n"]
  end.freeze

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
end

