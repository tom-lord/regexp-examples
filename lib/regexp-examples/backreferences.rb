module RegexpExamples
  class BackReferenceTracker
    @filled_groups = Hash.new { |h, v| h[v] = [] }
    class << self
      attr_accessor :filled_groups

      def add_filled_group(group_num, result_num, group)
        @filled_groups[group_num][result_num] = group
      end
    end
  end

  class BackReferenceReplacer
    def find_index_and_backref_ids(partial_examples)
      index_and_backref_ids = {}
      partial_examples.each_with_index do |partial_example, index|
        # TODO: Update this for named capture groups
        # TODO: Define this magic __X__ pattern as a constant? Maybe?
        if( partial_example.length == 1 \
              && partial_example.first =~ /__(\d+)__/ )
          index_and_backref_ids[index] = $1.to_i
        end
      end
      index_and_backref_ids
    end

    def substitute_backreferences(partial_examples)
      find_index_and_backref_ids(partial_examples).each do |index, backref_id|
        partial_examples[index] = BackReferenceTracker.filled_groups[backref_id]
      end
      partial_examples
    end
  end
end
