module RegexpExamples
  class Parser
    attr_reader :regexp_string
    def initialize(regexp_string)
      @regexp_string = regexp_string
      @num_groups = 0
      @current_position = 0
    end

    def parse
      repeaters = []
      while @current_position < regexp_string.length
        group = parse_group(repeaters)
        break if group.is_a? MultiGroupEnd
        repeaters = [] if group.is_a? OrGroup
        @current_position += 1
        repeaters << parse_repeater(group)
      end
      repeaters
    end

    private

    def parse_group(repeaters)
      char = regexp_string[@current_position]
      case char
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
      else
        group = parse_single_char_group(char)
      end
      group
    end

    def parse_after_backslash_group
      @current_position += 1
      case
      when regexp_string[@current_position..-1] =~ /^(\d+)/
        group = parse_backreference_group($&)
      when BackslashCharMap.keys.include?(regexp_string[@current_position])
        group = CharGroup.new(
          BackslashCharMap[regexp_string[@current_position]])
        # TODO: There are also a bunch of multi-char matches to watch out for:
        # http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Literals
      else
        group = parse_single_char_group( regexp_string[@current_position] )
        # TODO: What about cases like \A, \z, \Z ?
      end
      group
    end

    def parse_repeater(group)
      char = regexp_string[@current_position]
      case char
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
      this_group_num = @num_groups
      groups = parse
      # TODO: Non-capture groups, i.e. /...(?:foo).../
      # TODO: Named capture groups, i.e. /...(?<name>foo).../
      MultiGroup.new(groups, this_group_num)
    end

    def parse_multi_end_group
      MultiGroupEnd.new
    end

    def parse_char_group
      chars = []
      @current_position += 1
      # TODO: What about the sneaky edge case of /...[]a-z].../ ?
      until regexp_string[@current_position].chr == ']'
        chars << regexp_string[@current_position].chr
        @current_position += 1
      end
      CharGroup.new(chars)
    end

    def parse_dot_group
      DotGroup.new
    end

    def parse_or_group(left_repeaters)
      @current_position += 1
      right_repeaters = parse
      OrGroup.new(left_repeaters, right_repeaters)
    end


    def parse_single_char_group(char)
      SingleCharGroup.new(char)
    end

    def parse_backreference_group(match)
      BackReferenceGroup.new(match.to_i)
    end

    def parse_star_repeater(group)
      @current_position += 1
      StarRepeater.new(group)
    end

    def parse_plus_repeater(group)
      @current_position += 1
      PlusRepeater.new(group)
    end

    def parse_question_mark_repeater(group)
      @current_position += 1
      QuestionMarkRepeater.new(group)
    end

    def parse_range_repeater(group)
      match = regexp_string[@current_position..-1].match(/^\{(\d+)(,)?(\d+)?\}/)
      @current_position += match[0].size
      min = match[1].to_i if match[1]
      has_comma = !match[2].nil?
      max = match[3].to_i if match[3]
      RangeRepeater.new(group, min, has_comma, max)
    end

    def parse_one_time_repeater(group)
      OneTimeRepeater.new(group)
    end
  end
end

