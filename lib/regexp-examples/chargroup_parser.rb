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
    def initialize(regexp_string)
      @regexp_string = regexp_string
      @current_position = 0
    end

    def parse(is_sub_group: false)
      @charset = []
      @negative = false
      parse_first_chars(is_sub_group)
      until next_char == "]" do
        case next_char
        when "\\"
          @current_position += 1
          parse_after_backslash
        when "["
          @current_position += 1
          sub_group_parser = self.class.new(rest_of_string)
          sub_group_parser.parse(is_sub_group: true)
          @charset.concat sub_group_parser.result
          @current_position += sub_group_parser.length
        when "-"
          if regexp_string[@current_position + 1] == "]"
            @charset << "-"
            @current_position += 1
          else
            # TODO!!!
            # Add range from previous char -> next char
          end
        when "&"
          if regexp_string[@current_position + 1] == "&"
            # TODO!!!
            # Set intersection...
          else
            @charset << "&"
            @current_position += 1
          end
        else
          @charset << next_char
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
    def parse_first_chars(is_sub_group)
      if next_char == '^'
        @negative = true
        @current_position += 1
      end
      
      case rest_of_string
      when /\A[-\]]/ # e.g. /[]]/ (match "]") or /[-]/ (match "-")
        @charset << next_char
        @current_position += 1
      when /\A:([^:]+):\]/ # e.g. [[:alpha:]] - POSIX group
        if is_sub_group
          @charset.concat POSIXCharMap[$1]
          @current_position += ($1.length + 2)
        end
      end
    end

    def parse_after_backslash
      case next_char
      when *BackslashCharMap.keys
        @charset.concat BackslashCharMap[next_char]
      when 'b'
        @charset << "\b"
      else
        @charset << next_char
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

