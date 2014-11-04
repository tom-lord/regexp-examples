module RegexpExamples
  class BackReferenceTracker
    @filled_groups = {}
    class << self
      attr_accessor :filled_groups

      def add_filled_group(num, group)
        @filled_groups[num] = group
      end
    end
  end

  class BackReferenceReplacer
    def substitute_backreferences(full_example)
      # TODO: Update this for named capture groups
      # TODO: Define this magic __X__ pattern as a constant? Maybe?
      full_example.gsub!(/__(\d+)__/) do |_|
        BackReferenceTracker.filled_groups[$1.to_i]
      end
    end
  end
end
