module RegexpExamples
  IllegalSyntaxError = Class.new(StandardError)
  class Parser
    attr_reader :regexp_string
    def initialize(regexp_string, regexp_options)
      @regexp_string = regexp_string
      @ignorecase = !(regexp_options & Regexp::IGNORECASE).zero?
      @multiline = !(regexp_options & Regexp::MULTILINE).zero?
      @extended = !(regexp_options & Regexp::EXTENDED).zero?
      @num_groups = 0
      @current_position = 0
    end

    def parse
      repeaters = []
      until end_of_regexp
        group = parse_group(repeaters)
        return [group] if group.is_a? OrGroup
        @current_position += 1
        repeaters << parse_repeater(group)
      end
      repeaters
    end

    private

    def parse_group(repeaters)
      case next_char
      when '('
        parse_multi_group
      when '['
        parse_char_group
      when '.'
        parse_dot_group
      when '|'
        parse_or_group(repeaters)
      when '\\'
        parse_after_backslash_group
      when '^'
        parse_caret
      when '$'
        parse_dollar
      when /[#\s]/
        parse_extended_whitespace
      else
        parse_single_char_group(next_char)
      end
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

    def parse_caret
      if @current_position == 0
        return PlaceHolderGroup.new # Ignore the "illegal" character
      else
        raise_anchors_exception!
      end
    end

    def parse_dollar
      if @current_position == (regexp_string.length - 1)
        return PlaceHolderGroup.new # Ignore the "illegal" character
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

    def parse_after_backslash_group
      @current_position += 1
      case
      when rest_of_string =~ /\A(\d{1,3})/
        parse_regular_backreference_group(Regexp.last_match(1))
      when rest_of_string =~ /\Ak['<]([\w-]+)['>]/
        parse_named_backreference_group(Regexp.last_match(1))
      when BackslashCharMap.keys.include?(next_char)
        parse_backslash_special_char
      when rest_of_string =~ /\A(c|C-)(.)/
        parse_backslash_control_char(Regexp.last_match(1), Regexp.last_match(2))
      when rest_of_string =~ /\Ax(\h{1,2})/
        parse_backslash_escape_sequence(Regexp.last_match(1))
      when rest_of_string =~ /\Au(\h{4}|\{\h{1,4}\})/
        parse_backslash_unicode_sequence(Regexp.last_match(1))
      when rest_of_string =~ /\A(p)\{(\^?)([^}]+)\}/i
        parse_backslash_named_property(
          Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
        )
      when next_char == 'K' # Keep (special lookbehind that CAN be supported safely!)
        PlaceHolderGroup.new
      when next_char == 'R'
        parse_backslash_linebreak
      when next_char == 'g'
        parse_backslash_subexpresion_call
      when next_char =~ /[bB]/
        parse_backslash_anchor
      when next_char =~ /[AG]/
        parse_backslash_start_of_string
      when next_char =~ /[zZ]/
        # TODO: /\Z/ should be treated as /\n?/
        parse_backslash_end_of_string
      else
        parse_single_char_group(next_char)
      end
    end

    def parse_regular_backreference_group(group_id)
      @current_position += (group_id.length - 1) # In case of 10+ backrefs!
      parse_backreference_group(group_id)
    end

    def parse_named_backreference_group(group_name)
      @current_position += (group_name.length + 2)
      group_id = if group_name.to_i < 0
                   # RELATIVE group number, e.g. /(a)(b)(c)(d) \k<-2>/
                   @num_groups + group_name.to_i + 1
                 else
                   group_name
                 end
      parse_backreference_group(group_id)
    end

    def parse_backslash_special_char
      CharGroup.new(
        BackslashCharMap[next_char].dup,
        @ignorecase
      )
    end

    def parse_backslash_control_char(control_syntax, control_code)
      @current_position += control_syntax.length
      parse_single_char_group(parse_control_character(control_code))
    end

    def parse_backslash_escape_sequence(escape_sequence)
      @current_position += escape_sequence.length
      parse_single_char_group(parse_unicode_sequence(escape_sequence))
    end

    def parse_backslash_unicode_sequence(full_hex_sequence)
      @current_position += full_hex_sequence.length
      sequence = full_hex_sequence.match(/\h{1,4}/)[0] # Strip off "{" and "}"
      parse_single_char_group(parse_unicode_sequence(sequence))
    end

    def parse_backslash_named_property(p_negation, caret_negation, property_name)
      @current_position += (caret_negation.length + # 0 or 1, of '^' is present
                            property_name.length +
                            2) # Length of opening and closing brackets (always 2)
      # Beware of double negatives! E.g. /\P{^Space}/
      is_negative = (p_negation == 'P') ^ (caret_negation == '^')
      CharGroup.new(
        if is_negative
          CharSets::Any.dup - NamedPropertyCharMap[property_name.downcase]
        else
          NamedPropertyCharMap[property_name.downcase]
        end,
        @ignorecase
      )
    end

    def parse_backslash_linebreak
      CharGroup.new(
        ["\r\n", "\n", "\v", "\f", "\r"],
        @ignorecase
      ) # Using "\r\n" as one character is little bit hacky...
    end

    def parse_backslash_subexpresion_call
      fail IllegalSyntaxError,
        'Subexpression calls (\\g) cannot be supported, as they are not regular'
    end

    def parse_backslash_anchor
      raise_anchors_exception!
    end

    def parse_backslash_start_of_string
      if @current_position == 1
        PlaceHolderGroup.new
      else
        raise_anchors_exception!
      end
    end

    def parse_backslash_end_of_string
      if @current_position == (regexp_string.length - 1)
        PlaceHolderGroup.new
      else
        raise_anchors_exception!
      end
    end


    def parse_multi_group
      @current_position += 1
      @num_groups += 1
      remember_old_regexp_options do
        group_id = nil # init
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
            regexp_options_toggle(Regexp.last_match(1), Regexp.last_match(2))
            @num_groups -= 1 # Toggle "groups" should not increase backref group count
            @current_position += $&.length + 1
            if next_char == ':' # e.g. /(?i:subexpr)/
              @current_position += 1
            else
              return PlaceHolderGroup.new
            end
          when %w(! =).include?(match[2]) # e.g. /(?=lookahead)/, /(?!neglookahead)/
            fail IllegalSyntaxError,
                 'Lookaheads are not regular; cannot generate examples'
          when %w(! =).include?(match[3]) # e.g. /(?<=lookbehind)/, /(?<!neglookbehind)/
            fail IllegalSyntaxError,
                 'Lookbehinds are not regular; cannot generate examples'
          else # e.g. /(?<name>namedgroup)/
            @current_position += (match[3].length + 3)
            group_id = match[3]
          end
        end
        MultiGroup.new(parse, group_id)
      end
    end

    def remember_old_regexp_options
      previous_ignorecase = @ignorecase
      previous_multiline = @multiline
      previous_extended = @extended
      group = yield
      @ignorecase = previous_ignorecase
      @multiline = previous_multiline
      @extended = previous_extended
      group
    end

    def regexp_options_toggle(on, off)
      regexp_option_toggle(on, off, '@ignorecase', 'i')
      regexp_option_toggle(on, off, '@multiline', 'm')
      regexp_option_toggle(on, off, '@extended', 'x')
    end

    def regexp_option_toggle(on, off, var, char)
      instance_variable_set(var, true) if on.include? char
      instance_variable_set(var, false) if off.include? char
    end

    def parse_char_group
      @current_position += 1 # Skip past opening "["
      chargroup_parser = ChargroupParser.new(rest_of_string)
      parsed_chars = chargroup_parser.result
      @current_position += (chargroup_parser.length - 1) # Step back to closing "]"
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

    def parse_backreference_group(group_id)
      BackReferenceGroup.new(group_id)
    end

    def parse_control_character(char)
      (char.ord % 32).chr # Black magic!
      # eval "?\\C-#{char.chr}" # Doesn't work for e.g. char = "?"
    end

    def parse_unicode_sequence(match)
      [match.to_i(16)].pack('U')
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
      if min && !has_comma && !max && next_char == '?'
        repeater = parse_question_mark_repeater(repeater)
      else
        parse_reluctant_or_possessive_repeater
      end
      repeater
    end

    def raise_anchors_exception!
      fail IllegalSyntaxError,
           "Anchors ('#{next_char}') cannot be supported, as they are not regular"
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

    def end_of_regexp
      next_char == ')' || @current_position >= regexp_string.length
    end
  end
end
