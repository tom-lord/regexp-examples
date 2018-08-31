module RegexpExamples
  # A collection of related helper methods, utilised by the `Parser` class
  module ParseGroupHelper
    protected

    def parse_caret
      if @current_position.zero?
        PlaceHolderGroup.new # Ignore the "illegal" character
      else
        raise_anchors_exception!
      end
    end

    def parse_dollar
      if @current_position == (regexp_string.length - 1)
        PlaceHolderGroup.new # Ignore the "illegal" character
      else
        raise_anchors_exception!
      end
    end

    def parse_extended_whitespace
      if @extended
        skip_whitespace
        PlaceHolderGroup.new # Ignore the whitespace/comment
      else
        parse_single_char_group(next_char)
      end
    end

    def skip_whitespace
      whitespace_chars = rest_of_string.match(/#.*|\s+/)[0]
      @current_position += whitespace_chars.length - 1
    end

    def parse_single_char_group(char)
      SingleCharGroup.new(char, @ignorecase)
    end

    def parse_char_group
      @current_position += 1 # Skip past opening "["
      chargroup_parser = ChargroupParser.new(rest_of_string)
      chargroup_parser.parse
      @current_position += (chargroup_parser.length - 1) # Step back to closing "]"
      CharGroup.new(chargroup_parser.result, @ignorecase)
    end

    def parse_dot_group
      DotGroup.new(@multiline)
    end

    def parse_or_group(left_repeaters)
      @current_position += 1
      right_repeaters = parse
      OrGroup.new(left_repeaters, right_repeaters)
    end
  end
end
