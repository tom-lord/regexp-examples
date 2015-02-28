module RegexpExamples
  class BackReferenceReplacer
    BackrefNotFound = Class.new(StandardError)

    def substitute_backreferences(full_examples)
      full_examples.map do |full_example|
        begin
          while full_example.match(/__(\w+?)__/)
            full_example.sub!(/__(\w+?)__/, find_backref_for(full_example, $1))
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
        raise(BackrefNotFound)
      end
    end

  end

end
