module RegexpExamples
  class BaseRepeater
    attr_reader :group, :min_repeats, :max_repeats
    def initialize(group)
      @group = group
    end

    def result
      group_results = group.result.first(RegexpExamples.max_group_results)
      results = []
      min_repeats.upto(max_repeats) do |repeats|
        if repeats.zero?
          results << [GroupResult.new('')]
        else
          results << RegexpExamples.permutations_of_strings(
            [group_results] * repeats
          )
        end
      end
      results.flatten.uniq
    end

    def random_result
      result = []
      rand(min_repeats..max_repeats).times { result << group.random_result }
      result << [GroupResult.new('')] if result.empty? # in case of 0.times
      RegexpExamples.permutations_of_strings(result)
    end
  end

  class OneTimeRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 1
      @max_repeats = 1
    end
  end

  class StarRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 0
      @max_repeats = RegexpExamples.max_repeater_variance
    end
  end

  class PlusRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 1
      @max_repeats = RegexpExamples.max_repeater_variance + 1
    end
  end

  class QuestionMarkRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 0
      @max_repeats = 1
    end
  end

  class RangeRepeater < BaseRepeater
    def initialize(group, min, has_comma, max)
      super(group)
      @min_repeats = min || 0
      if max # e.g. {1,100} --> Treat as {1,3} or similar, to prevent a huge number of results
        @max_repeats = smallest(max, @min_repeats + RegexpExamples.max_repeater_variance)
      elsif has_comma # e.g. {2,} --> Treat as {2,4} or similar
        @max_repeats = @min_repeats + RegexpExamples.max_repeater_variance
      else # e.g. {3} --> Treat as {3,3}
        @max_repeats = @min_repeats
      end
    end

    private

    def smallest(x, y)
      (x < y) ? x : y
    end
  end
end
