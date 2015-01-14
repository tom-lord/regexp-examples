module RegexpExamples
  class BaseRepeater
    attr_reader :group
    def initialize(group)
      @group = group
    end

    def result(min_repeats, max_repeats)
      group_results = @group.result[0 .. MaxGroupResults-1]
      results = []
      min_repeats.upto(max_repeats) do |repeats|
        group_results.each do |group_result|
          results << group_result * repeats
        end
      end
      results.uniq
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
      super(0, TIMES)
    end
  end

  class PlusRepeater < BaseRepeater
    def initialize(group)
      super
    end

    def result
      super(1, TIMES)
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
        @max = max
      elsif has_comma
        @max = min + TIMES
      else
        @max = min
      end
    end

    def result
      super(@min, @max)
    end
  end
end

