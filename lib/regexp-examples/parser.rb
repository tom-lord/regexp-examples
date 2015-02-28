module RegexpExamples
  IllegalSyntaxError = Class.new(StandardError)
  class Parser
    attr_reader :regexp_string
    def initialize(regexp_string, regexp_options, config_options={})
      @regexp_string = regexp_string
      @ignorecase = !(regexp_options & Regexp::IGNORECASE).zero?
      @multiline = !(regexp_options & Regexp::MULTILINE).zero?
      @extended = !(regexp_options & Regexp::EXTENDED).zero?
      @num_groups = 0
      @current_position = 0
      ResultCountLimiters.configure!(
        config_options[:max_repeater_variance],
        config_options[:max_group_results]
      )
    end

    def parse
      repeaters = []
      while @current_position < regexp_string.length
        group = parse_group(repeaters)
        break if group.is_a? MultiGroupEnd
        if group.is_a? OrGroup
          return [OneTimeRepeater.new(group)]
        end
        @current_position += 1
        repeaters << parse_repeater(group)
      end
      repeaters
    end

    private

    def parse_group(repeaters)
      case next_char
      when '('
        group = parse_multi_group
      when ')'
        group = parse_multi_end_group
      when '['
        group = parse_char_group
      when '.'
        group = parse_dot_group
      when '|'
        group = parse_or_group(repeaters)
      when '\\'
        group = parse_after_backslash_group
      when '^'
        if @current_position == 0
          group = PlaceHolderGroup.new # Ignore the "illegal" character
        else
          raise IllegalSyntaxError, "Anchors ('#{next_char}') cannot be supported, as they are not regular"
        end
      when '$'
        if @current_position == (regexp_string.length - 1)
          group = PlaceHolderGroup.new # Ignore the "illegal" character
        else
          raise IllegalSyntaxError, "Anchors ('#{next_char}') cannot be supported, as they are not regular"
        end
      when /[#\s]/
        if @extended
          parse_extended_whitespace
          group = PlaceHolderGroup.new # Ignore the whitespace/comment
        else
          group = parse_single_char_group(next_char)
        end
      else
        group = parse_single_char_group(next_char)
      end
      group
    end

    def parse_extended_whitespace
      whitespace_chars = rest_of_string.match(/#.*|\s+/)[0]
      @current_position += whitespace_chars.length - 1
    end

    def parse_after_backslash_group
      @current_position += 1
      case
      when rest_of_string =~ /\A(\d{1,3})/
        @current_position += ($1.length - 1) # In case of 10+ backrefs!
        group = parse_backreference_group($1)
      when rest_of_string =~ /\Ak<([^>]+)>/ # Named capture group
        @current_position += ($1.length + 2)
        group = parse_backreference_group($1)
      when BackslashCharMap.keys.include?(next_char)
        group = CharGroup.new(
          BackslashCharMap[next_char].dup,
          @ignorecase
        )
      when rest_of_string =~ /\A(c|C-)(.)/ # Control character
        @current_position += $1.length
        group = parse_single_char_group( parse_control_character($2) )
      when rest_of_string =~ /\Ax(\h{1,2})/ # Escape sequence
        @current_position += $1.length
        group = parse_single_char_group( parse_escape_sequence($1) )
      when rest_of_string =~ /\Au(\h{4}|\{\h{1,4}\})/ # Unicode sequence
        @current_position += $1.length
        sequence = $1.match(/\h{1,4}/)[0] # Strip off "{" and "}"
        group = parse_single_char_group( parse_unicode_sequence(sequence) )
      when rest_of_string =~ /\Ap\{(\^?)([^}]+)\}/ # Named properties
        @current_position += ($1.length + $2.length + 2)
        group = CharGroup.new(
          if($1 == "^")
            CharSets::Any.dup - NamedPropertyCharMap[$2.downcase]
          else
            NamedPropertyCharMap[$2.downcase]
          end,
          @ignorecase
        )
      when next_char == 'K' # Keep (special lookbehind that CAN be supported safely!)
        group = PlaceHolderGroup.new
      when next_char == 'R' # Linebreak
        group = CharGroup.new(["\r\n", "\n", "\v", "\f", "\r"], @ignorecase) # A bit hacky...
      when next_char == 'g' # Subexpression call
        raise IllegalSyntaxError, "Subexpression calls (\g) are not yet supported"
      when next_char =~ /[bB]/ # Anchors
        raise IllegalSyntaxError, "Anchors ('\\#{next_char}') cannot be supported, as they are not regular"
      when next_char =~ /[AG]/ # Start of string
        if @current_position == 1
          group = PlaceHolderGroup.new
        else
          raise IllegalSyntaxError, "Anchors ('\\#{next_char}') cannot be supported, as they are not regular"
        end
      when next_char =~ /[zZ]/ # End of string
        if @current_position == (regexp_string.length - 1)
          group = PlaceHolderGroup.new
        else
          raise IllegalSyntaxError, "Anchors ('\\#{next_char}') cannot be supported, as they are not regular"
        end
      else
        group = parse_single_char_group( next_char )
      end
      group
    end

    def parse_repeater(group)
      case next_char
      when '*'
        repeater = parse_star_repeater(group)
      when '+'
        repeater = parse_plus_repeater(group)
      when '?'
        repeater = parse_question_mark_repeater(group)
      when '{'
        repeater = parse_range_repeater(group)
      else
        repeater = parse_one_time_repeater(group)
      end
      repeater
    end

    def parse_multi_group
      @current_position += 1
      @num_groups += 1
      group_id = nil # init
      previous_ignorecase = @ignorecase
      previous_multiline = @multiline
      previous_extended = @extended
      rest_of_string.match(
        /
          \A
          (\?)?               # Is it a "special" group, i.e. starts with a "?"?
            (
              :               # Non capture group
              |!              # Neglookahead
              |=              # Lookahead
              |\#             # Comment group
              |<              # Lookbehind or named capture
              (
                !             # Neglookbehind
                |=            # Lookbehind
                |[^>]+        # Named capture
              )
              |[mix]*-?[mix]* # Option toggle
          )?
        /x
      ) do |match|
        case
        when match[1].nil? # e.g. /(normal)/
          group_id = @num_groups.to_s
        when match[2] == ':' # e.g. /(?:nocapture)/
          @current_position += 2
        when match[2] == '#' # e.g. /(?#comment)/
          comment_group = rest_of_string.match(/.*?[^\\](?:\\{2})*\)/)[0]
          @current_position += comment_group.length
        when match[2] =~ /\A(?=[mix-]+)([mix]*)-?([mix]*)/ # e.g. /(?i-mx)/
          regexp_options_toggle($1, $2)
          @current_position += $&.length + 1
          if next_char == ':' # e.g. /(?i:subexpr)/
            @current_position += 1
          else
            return PlaceHolderGroup.new
          end
        when %w(! =).include?(match[2]) # e.g. /(?=lookahead)/, /(?!neglookahead)/
          raise IllegalSyntaxError, "Lookaheads are not regular; cannot generate examples"
        when %w(! =).include?(match[3]) # e.g. /(?<=lookbehind)/, /(?<!neglookbehind)/
          raise IllegalSyntaxError, "Lookbehinds are not regular; cannot generate examples"
        else # e.g. /(?<name>namedgroup)/
          @current_position += (match[3].length + 3)
          group_id = match[3]
        end
      end
      groups = parse
      @ignorecase = previous_ignorecase
      @multiline = previous_multiline
      @extended = previous_extended
      MultiGroup.new(groups, group_id)
    end

    def regexp_options_toggle(on, off)
      @ignorecase = true if (on.include? "i")
      @ignorecase = false if (off.include? "i")
      @multiline = true if (on.include? "m")
      @multiline = false if (off.include? "m")
      @extended = true if (on.include? "x")
      @extended = false if (off.include? "x")
    end

    def parse_multi_end_group
      MultiGroupEnd.new
    end

    def parse_char_group
      # TODO: Extract all this logic into ChargroupParser
      if rest_of_string =~ /\A\[\[:(\^?)([^:]+):\]\]/
        @current_position += (6 + $1.length + $2.length)
        chars = $1.empty? ? POSIXCharMap[$2] : CharSets::Any - POSIXCharMap[$2]
        return CharGroup.new(chars, @ignorecase)
      end
      chars = []
      @current_position += 1
      if next_char == ']'
        # Beware of the sneaky edge case:
        # /[]]/ (match "]")
        chars << ']'
        @current_position += 1
      end
      until next_char == ']' \
        && !regexp_string[0..@current_position-1].match(/[^\\](\\{2})*\\\z/)
        # Beware of having an ODD number of "\" before the "]", e.g.
        # /[\]]/ (match "]")
        # /[\\]/ (match "\")
        # /[\\\]]/ (match "\" or "]")
        chars << next_char
        @current_position += 1
      end
      parsed_chars = ChargroupParser.new(chars).result
      CharGroup.new(parsed_chars, @ignorecase)
    end

    def parse_dot_group
      DotGroup.new(@multiline)
    end

    def parse_or_group(left_repeaters)
      @current_position += 1
      right_repeaters = parse
      OrGroup.new(left_repeaters, right_repeaters)
    end


    def parse_single_char_group(char)
      SingleCharGroup.new(char, @ignorecase)
    end

    def parse_backreference_group(match)
      BackReferenceGroup.new(match)
    end

    def parse_control_character(char)
      (char.ord % 32).chr # Black magic!
      # eval "?\\C-#{char.chr}" # Doesn't work for e.g. char = "?"
    end

    def parse_escape_sequence(match)
      eval "?\\x#{match}"
    end

    def parse_unicode_sequence(match)
      eval "?\\u{#{match}}"
    end

    def parse_star_repeater(group)
      @current_position += 1
      parse_reluctant_or_possessive_repeater
      StarRepeater.new(group)
    end

    def parse_plus_repeater(group)
      @current_position += 1
      parse_reluctant_or_possessive_repeater
      PlusRepeater.new(group)
    end

    def parse_reluctant_or_possessive_repeater
      if next_char =~ /[?+]/
        # Don't treat these repeaters any differently when generating examples
        @current_position += 1
      end
    end

    def parse_question_mark_repeater(group)
      @current_position += 1
      parse_reluctant_or_possessive_repeater
      QuestionMarkRepeater.new(group)
    end

    def parse_range_repeater(group)
      match = rest_of_string.match(/\A\{(\d+)?(,)?(\d+)?\}/)
      @current_position += match[0].size
      min = match[1].to_i if match[1]
      has_comma = !match[2].nil?
      max = match[3].to_i if match[3]
      repeater = RangeRepeater.new(group, min, has_comma, max)
      parse_reluctant_or_possessive_range_repeater(repeater, min, has_comma, max)
    end

    def parse_reluctant_or_possessive_range_repeater(repeater, min, has_comma, max)
        # .{1}? should be equivalent to (?:.{1})?, i.e. NOT a "non-greedy quantifier"
        if min && !has_comma && !max && next_char == "?"
          repeater = parse_question_mark_repeater(repeater)
        else
          parse_reluctant_or_possessive_repeater
        end
        repeater
    end

    def parse_one_time_repeater(group)
      OneTimeRepeater.new(group)
    end

    def rest_of_string
      regexp_string[@current_position..-1]
    end

    def next_char
      regexp_string[@current_position]
    end
  end
end

