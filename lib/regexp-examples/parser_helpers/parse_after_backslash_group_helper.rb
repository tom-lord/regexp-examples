module RegexpExamples
  module ParseAfterBackslashGroupHelper
  protected
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

    def parse_backreference_group(group_id)
      BackReferenceGroup.new(group_id)
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

    def parse_control_character(char)
      (char.ord % 32).chr # Black magic!
      # eval "?\\C-#{char.chr}" # Doesn't work for e.g. char = "?"
    end

    def parse_unicode_sequence(match)
      [match.to_i(16)].pack('U')
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

    def raise_anchors_exception!
      fail IllegalSyntaxError,
           "Anchors ('#{next_char}') cannot be supported, as they are not regular"
    end
  end
end

