module RegexpExamples
  class CaptureGroupResult < String
    attr_reader :group_id, :subgroups
    def initialize(group_id, subgroups, values)
      @group_id = group_id
      @subgroups = subgroups
      super(values)
    end

    def all_subgroups
      [self, subgroups].flatten
    end

    # Overridden in order to preserve the @group_id and @subgroups
    def *(int)
      self.class.new(group_id, subgroups, super)
    end
    # Overridden in order to preserve the @group_id and @subgroups
    def gsub(regex)
      self.class.new(group_id, subgroups, super)
    end
  end

  class BackReferenceReplacer
    def substitute_backreferences(full_examples)
      full_examples.map! do |full_example|
        if full_example.is_a? String
          [full_example]
        else
          full_example.map! do |partial_example|
            partial_example.gsub(/__(\w+)__/) do |match|
              find_backref_for(full_example, $1)
            end
          end
        end
      end
      full_examples
    end

    private
    def find_backref_for(full_example, group_id)
      full_example.each do |partial_example|
        next unless partial_example.respond_to?(:group_id)
          partial_example.all_subgroups.each do |subgroup|
            return subgroup if subgroup.group_id == group_id
          end
      end
    end

  end

end
