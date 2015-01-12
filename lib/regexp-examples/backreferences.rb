module RegexpExamples
  class CaptureGroupResult < String
    attr_reader :group_id, :subgroups
    def initialize(group_id, subgroups, values)
      @group_id = group_id
      @subgroups = subgroups
      super(values)
    end

    # Overridden in order to preserve the @group_id and @subgroups
    def *(int)
      self.class.new(group_id, subgroups, super)
    end
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
        case
        when partial_example.group_id == group_id
          return partial_example
        when sub_partial_example = find_backref_for(partial_example.subgroups, group_id)
          # TODO: This line does NOT work for all nested backreference groups
          # Need to revisit this logic and find a better solution, if possible
          return sub_partial_example.result.detect{|sub_partial_result| partial_example.include? sub_partial_result}
        end
      end
      nil
    end

  end

end
