require_relative 'parser_helpers/parse_group_helper'
require_relative 'parser_helpers/parse_after_backslash_group_helper'
require_relative 'parser_helpers/parse_multi_group_helper'
require_relative 'parser_helpers/parse_repeater_helper'
require_relative 'parser_helpers/charset_negation_helper'

# :nodoc:
module RegexpExamples
  IllegalSyntaxError = Class.new(StandardError)
  # A Regexp parser, used to build a structured collection of objects that represents
  # the regular expression.
  # This object can then be used to generate strings that match the regular expression.
  class Parser
    include ParseGroupHelper
    include ParseAfterBackslashGroupHelper
    include ParseMultiGroupHelper
    include ParseRepeaterHelper
    include CharsetNegationHelper

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
        parse_star_repeater(group)
      when '+'
        parse_plus_repeater(group)
      when '?'
        parse_question_mark_repeater(group)
      when '{'
        parse_range_repeater(group)
      else
        parse_one_time_repeater(group)
      end
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
