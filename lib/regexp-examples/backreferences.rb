module RegexpExamples
  class GroupResult < String
    attr_reader :group_id, :subgroups
    def initialize(result, group_id = nil, subgroups = [])
      @group_id = group_id
      @subgroups = subgroups
      if result.respond_to?(:group_id)
        @subgroups = result.all_subgroups
      end
      super(result)
    end

    def all_subgroups
      [self, subgroups].flatten.reject { |subgroup| subgroup.group_id.nil? }
    end

    # Overridden in order to preserve the @group_id and @subgroups
    def *(int)
      self.class.new(super.to_s, group_id, subgroups)
    end
    # Overridden in order to preserve the @group_id and @subgroups
    def gsub(regex)
      self.class.new(super.to_s, group_id, subgroups)
    end
  end

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
