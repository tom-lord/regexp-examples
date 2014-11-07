module RegexpExamples
  class CaptureGroupResult < String
    attr_reader :group_ids
    def initialize(group_ids, values)
      @group_ids = group_ids
      super(values)
    end

    # Overridden in order to preserve the @group_id
    # This was bloody hard to debug!!!
    def *(int)
      self.class.new(group_ids, super)
    end
    def gsub(regex)
      self.class.new(group_ids, super)
    end
  end

  class BackReferenceReplacer
    def substitute_backreferences(full_examples)
      full_examples.map! do |full_example|
        if full_example.is_a? String
          [full_example]
        else
          full_example.map! do |partial_example|
            partial_example.gsub(/__(\d+)__/) do |match|
              find_backref_for(full_example, $1.to_i)
            end
          end
        end
      end
      full_examples
    end

    private
    def find_backref_for(full_example, group_id)
      full_example.detect do |partial_example|
        partial_example.respond_to?(:group_ids) \
          && partial_example.group_ids.include?(group_id)
      end.to_s
    end
  end

end
