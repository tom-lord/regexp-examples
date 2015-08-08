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
    BackrefNotFound = Class.new(StandardError)

    def substitute_backreferences(full_examples)
      full_examples.map do |full_example|
        begin
          while full_example.match(/__(\w+?)__/)
            full_example.sub!(
              /__(\w+?)__/,
              find_backref_for(full_example, Regexp.last_match(1))
            )
          end
          full_example
        rescue BackrefNotFound
          # For instance, one "full example" from /(a|(b)) \2/: "a __2__"
          # should be rejected because the backref (\2) does not exist
          nil
        end
      end.compact
    end

    private

    def find_backref_for(full_example, group_id)
      full_example.all_subgroups.detect do |subgroup|
        subgroup.group_id == group_id
      end || octal_char_for(group_id)
    end

    def octal_char_for(octal_chars)
      # For octal characters in the range \10 - \177
      if octal_chars =~ /\A[01]?[0-7]{1,2}\z/ && octal_chars.to_i >= 10
        Integer(octal_chars, 8).chr
      else
        fail(BackrefNotFound)
      end
    end
  end
end
