module RegexpExamples
  class BackReferenceReplacer
    def substitute_backreferences(full_examples)
      full_examples.map do |full_example|
        while full_example.match(/__(\w+?)__/)
          full_example.sub!(/__(\w+?)__/, find_backref_for(full_example, $1))
        end
        full_example
      end
    end

    private
    def find_backref_for(full_example, group_id)
      full_example.all_subgroups.detect do |subgroup|
        subgroup.group_id == group_id
      end
    end

  end

end
