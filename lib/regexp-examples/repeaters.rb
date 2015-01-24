module RegexpExamples
  class BaseRepeater
    attr_reader :group
    def initialize(group)
      @group = group
    end

    def result(min_repeats, max_repeats)
      group_results = @group.result[0 .. RegexpExamples.MaxGroupResults-1]
      results = []
      min_repeats.upto(max_repeats) do |repeats|
        if repeats.zero?
          results << [ GroupResult.new('') ]
        else
          results << RegexpExamples.permutations_of_strings(
            [group_results] * repeats
          )
        end
      end
      results.flatten.uniq
    end
  end

  class OneTimeRepeater < BaseRepeater
    def initialize(group)
      super
    end

    def result
      super(1, 1)
    end
  end

  class StarRepeater < BaseRepeater
    def initialize(group)
      super
    end

    def result
      super(0, RegexpExamples.MaxRepeaterVariance)
    end
  end

  class PlusRepeater < BaseRepeater
    def initialize(group)
      super
    end

    def result
      super(1, RegexpExamples.MaxRepeaterVariance + 1)
    end
  end

  class QuestionMarkRepeater < BaseRepeater
    def initialize(group)
      super
    end

    def result
      super(0, 1)
    end
  end

  class RangeRepeater < BaseRepeater
    def initialize(group, min, has_comma, max)
      super(group)
      @min = min || 0
      if max
        # Prevent huge number of results in case of e.g. /.{1,100}/.examples
        @max = smallest(max, @min + RegexpExamples.MaxRepeaterVariance)
      elsif has_comma
        @max = @min + RegexpExamples.MaxRepeaterVariance
      else
        @max = @min
      end
    end

    def result
      super(@min, @max)
    end

    private
    def smallest(x, y)
      (x < y) ? x : y
    end
  end
end

