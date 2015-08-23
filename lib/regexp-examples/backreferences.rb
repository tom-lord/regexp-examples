module RegexpExamples
  # A helper class to fill-in backrefences AFTER the example(s) have been generated.
  # In a nutshell, this works by doing the following:
  # * Given a regex that contains a capute group and backreference, e.g. `/(a|b) \1/`
  # * After generating examples, the backreference is tored as a placeholder:
  #   `["a __1__", "b __1__"]`
  # * This class is used to fill in each placeholder accordingly:
  #   `["a a", "b b"]`
  # * Also, beware of octal groups and cases where the backref invalidates the example!!
  class BackReferenceReplacer
    # Named capture groups can only contain alphanumeric chars, and hyphens
    PLACEHOLDER_REGEX = Regexp.new(
      RegexpExamples::BackReferenceGroup::PLACEHOLDER_FORMAT % '([a-zA-Z0-9-]+)'
    )

    def substitute_backreferences(full_examples)
      full_examples.map do |full_example|
        # For instance, one "full example" from /(a|(b)) \2/: "a __2__"
        # should be rejected because the backref (\2) does not exist
        catch(:backref_not_found) do
          substitute_backrefs_one_at_a_time(full_example)
        end
      end.compact
    end

    private

    def substitute_backrefs_one_at_a_time(full_example)
      while full_example.match(PLACEHOLDER_REGEX) do
        full_example.sub!(
          PLACEHOLDER_REGEX,
          find_backref_for(full_example, Regexp.last_match(1))
        )
      end
      full_example
    end

    def find_backref_for(full_example, group_id)
      full_example.all_subgroups.detect do |subgroup|
        subgroup.group_id == group_id
      end || octal_char_for(group_id)
    end

    def octal_char_for(octal_chars)
      # For octal characters in the range \00 - \177
      if octal_chars =~ /\A[01]?[0-7]{1,2}\z/ && octal_chars.length > 1
        Integer(octal_chars, 8).chr
      else
        throw :backref_not_found
      end
    end
  end
end
