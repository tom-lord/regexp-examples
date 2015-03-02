module RegexpExamples
  # A "sub-parser", for char groups in a regular expression
  # Some examples of what this class needs to parse:
  # [abc]          - plain characters
  # [a-z]          - ranges
  # [\n\b\d]       - escaped characters (which may represent character sets)
  # [^abc]         - negated group
  # [[a][bc]]      - sub-groups (should match "a", "b" or "c")
  # [[:lower:]]    - POSIX group
  # [[a-f]&&[d-z]] - set intersection (should match "d", "f" or "f")
  # [[^:alpha:]&&[\n]a-c] - all of the above!!!! (should match "\n")
  class ChargroupParser
    attr_reader :regexp_string
    def initialize(regexp_string, is_sub_group: false)
      @regexp_string = regexp_string
      @is_sub_group = is_sub_group
      @current_position = 0
      parse
    end

    def parse
      @charset = []
      @negative = false
      parse_first_chars
      until next_char == "]" do
        case next_char
        when "["
          @current_position += 1
          sub_group_parser = self.class.new(rest_of_string, is_sub_group: true)
          @charset.concat sub_group_parser.result
          @current_position += sub_group_parser.length
        when "-"
          if regexp_string[@current_position + 1] == "]" # e.g. /[abc-]/ -- not a range!
            @charset << "-"
            @current_position += 1
          else
            @current_position += 1
            @charset.concat (@charset.last .. parse_checking_backlash.first).to_a
            @current_position += 1
          end
        when "&"
          if regexp_string[@current_position + 1] == "&"
            @current_position += 2
            sub_group_parser = self.class.new(rest_of_string, is_sub_group: @is_sub_group)
            @charset &= sub_group_parser.result
            @current_position += (sub_group_parser.length - 1)
          else
            @charset << "&"
            @current_position += 1
          end
        else
          @charset.concat parse_checking_backlash
          @current_position += 1
        end
      end

      @charset.uniq!
      @current_position += 1 # To account for final "]"
    end

    def length
      @current_position
    end

    def result
      @negative ? (CharSets::Any - @charset) : @charset
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
        if @is_sub_group
          chars = $1.empty? ? POSIXCharMap[$2] : (CharSets::Any - POSIXCharMap[$2])
          @charset.concat chars
          @current_position += ($1.length + $2.length + 2)
        end
      end
    end

    # Always returns an Array, for consistency
    def parse_checking_backlash
      if next_char == "\\"
        @current_position += 1
        parse_after_backslash
      else
        [next_char]
      end
    end

    def parse_after_backslash
      case next_char
      when *BackslashCharMap.keys
        BackslashCharMap[next_char]
      when 'b'
        ["\b"]
      else
        [next_char]
      end
    end

    def rest_of_string
      regexp_string[@current_position..-1]
    end

    def next_char
      regexp_string[@current_position]
    end
  end
end

