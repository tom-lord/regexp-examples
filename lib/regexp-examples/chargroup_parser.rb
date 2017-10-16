require_relative 'parser_helpers/charset_negation_helper'

module RegexpExamples
  # A "sub-parser", for char groups in a regular expression
  # Some examples of what this class needs to parse:
  # [abc]          - plain characters
  # [a-z]          - ranges
  # [\n\b\d]       - escaped characters (which may represent character sets)
  # [^abc]         - negated group
  # [[a][bc]]      - sub-groups (should match "a", "b" or "c")
  # [[:lower:]]    - POSIX group
  # [[a-f]&&[d-z]] - set intersection (should match "d", "e" or "f")
  # [[^:alpha:]&&[\n]a-c] - all of the above!!!! (should match "\n")
  class ChargroupParser
    include CharsetNegationHelper

    attr_reader :regexp_string, :current_position
    alias length current_position

    def initialize(regexp_string, is_sub_group: false)
      @regexp_string = regexp_string
      @is_sub_group = is_sub_group
      @current_position = 0
      @charset = []
      @negative = false
    end

    def parse
      parse_first_chars
      until next_char == ']'
        case next_char
        when '['
          parse_sub_group_concat
        when '-'
          parse_after_hyphen
        when '&'
          parse_after_ampersand
        else
          @charset.concat parse_checking_backlash
          @current_position += 1
        end
      end

      @charset.uniq!
      @current_position += 1 # To account for final "]"
    end

    def result
      negate_if(@charset, @negative)
    end

    private

    def parse_first_chars
      if next_char == '^'
        @negative = true
        @current_position += 1
      end

      case rest_of_string
      when /\A[-\]]/ # e.g. /[]]/ (match "]") or /[-]/ (match "-")
        @charset << next_char
        @current_position += 1
      when /\A:(\^?)([^:]+):\]/ # e.g. [[:alpha:]] - POSIX group
        parse_posix_group(Regexp.last_match(1), Regexp.last_match(2)) if @is_sub_group
      end
    end

    def parse_posix_group(negation_flag, name)
      @charset.concat negate_if(CharSets::POSIXCharMap[name], !negation_flag.empty?)
      @current_position += (negation_flag.length + # 0 or 1, if '^' is present
                            name.length +
                            2) # Length of opening and closing colons (always 2)
    end

    # Always returns an Array, for consistency
    def parse_checking_backlash
      if next_char == '\\'
        @current_position += 1
        parse_after_backslash
      else
        [next_char]
      end
    end

    def parse_after_backslash
      if next_char == 'b'
        ["\b"]
      else
        CharSets::BackslashCharMap.fetch(next_char, [next_char])
      end
    end

    def parse_sub_group_concat
      @current_position += 1
      sub_group_parser = self.class.new(rest_of_string, is_sub_group: true)
      sub_group_parser.parse
      @charset.concat sub_group_parser.result
      @current_position += sub_group_parser.length
    end

    def parse_after_ampersand
      if regexp_string[@current_position + 1] == '&'
        parse_sub_group_intersect
      else
        @charset << '&'
        @current_position += 1
      end
    end

    def parse_sub_group_intersect
      @current_position += 2
      sub_group_parser = self.class.new(rest_of_string, is_sub_group: true)
      sub_group_parser.parse
      @charset &= sub_group_parser.result
      @current_position += (sub_group_parser.length - 1)
    end

    def parse_after_hyphen
      if regexp_string[@current_position + 1] == ']' # e.g. /[abc-]/ -- not a range!
        @charset << '-'
      else
        @current_position += 1
        @charset.concat((@charset.last..parse_checking_backlash.first).to_a)
      end
      @current_position += 1
    end

    def rest_of_string
      regexp_string[@current_position..-1]
    end

    def next_char
      regexp_string[@current_position]
    end
  end
end
