module RegexpExamples
  module ParseRepeaterHelper
    protected
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
  end
end

