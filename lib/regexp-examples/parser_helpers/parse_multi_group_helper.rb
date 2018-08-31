module RegexpExamples
  # A collection of related helper methods, utilised by the `Parser` class
  module ParseMultiGroupHelper
    protected

    def parse_multi_group
      # TODO: Clean up this ugly mess of a method!
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
              |~              # Absent operator (ruby 2.4.1+)
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
          if match[1].nil? # e.g. /(normal)/
            group_id = @num_groups.to_s
          elsif match[2] == ':' # e.g. /(?:nocapture)/
            @num_groups -= 1
            @current_position += 2
          elsif match[2] == '#' # e.g. /(?#comment)/
            @num_groups -= 1
            comment_group = rest_of_string.match(/.*?[^\\](?:\\{2})*(?=\))/)[0]
            @current_position += comment_group.length
            return PlaceHolderGroup.new
          elsif match[2] == '~' # e.g. /(?~absent operator)/
            # The "best" way to replicate this is with a negative lookbehind:
            # e.g. (?~abc) --> (?:.(?<!abc))*
            # But since look-behinds are irregular, this library cannot support
            # that! A possible workaround would be to replace the group with a
            # repetition of the first letter negated, e.g.
            # (?~abc) --> (?:[^a]*)
            # However (!!) this generalisation is not always possible:
            # (?~\wa|\Wb) --> ???
            # Therefore, the only 100% reliable option is just to match "nothing"
            @num_groups -= 1 # "Absence groups" are not counted as backrefs
            absence_group = rest_of_string.match(/.*?[^\\](?:\\{2})*(?=\))/)[0]
            @current_position += absence_group.length
            return PlaceHolderGroup.new
          elsif match[2] =~ /\A(?=[mix-]+)([mix]*)-?([mix]*)/ # e.g. /(?i-mx)/
            regexp_options_toggle(Regexp.last_match(1), Regexp.last_match(2))
            @num_groups -= 1 # Toggle "groups" should not increase backref group count
            @current_position += $&.length + 1
            if next_char == ':' # e.g. /(?i:subexpr)/
              @current_position += 1
            else
              return PlaceHolderGroup.new
            end
          elsif %w[! =].include?(match[2]) # e.g. /(?=lookahead)/, /(?!neglookahead)/
            raise IllegalSyntaxError,
              'Lookaheads are not regular; cannot generate examples'
          elsif %w[! =].include?(match[3]) # e.g. /(?<=lookbehind)/, /(?<!neglookbehind)/
            raise IllegalSyntaxError,
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
  end
end
