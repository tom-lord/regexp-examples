module RegexpExamples
  # An abstract base class for all other repeater groups.
  # Since all repeaters (quantifiers) are really just shorthand syntaxes for the generic:
  # `/.{a,b}/`, the methods for generating "between `a` and `b` results" are fully
  # generalised here.
  class BaseRepeater
    attr_reader :group, :min_repeats, :max_repeats
    def initialize(group)
      @group = group
    end

    def result
      group_results = group.result.first(RegexpExamples::Config.max_group_results)
      results = []
      max_results_limiter = MaxResultsLimiterBySum.new
      min_repeats.upto(max_repeats) do |repeats|
        result = if repeats.zero?
                   [GroupResult.new('')]
                 else
                   RegexpExamples.permutations_of_strings(
                     [group_results] * repeats
                   )
                 end
        results << max_results_limiter.limit_results(result)
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

  # When there is "no repeater", we interpret this as a "one time repeater".
  # For example, `/a/` is a "OneTimeRepeater" of "a"
  # Equivalent to `/a{1}/`
  class OneTimeRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 1
      @max_repeats = 1
    end
  end

  # When a klein star is used, e.g. `/a*/`
  # Equivalent to `/a{0,}/`
  class StarRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 0
      @max_repeats = RegexpExamples::Config.max_repeater_variance
    end
  end

  # When a plus is used, e.g. `/a+/`
  # Equivalent to `/a{1,}/`
  class PlusRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 1
      @max_repeats = RegexpExamples::Config.max_repeater_variance + 1
    end
  end

  # When a question mark is used, e.g. `/a?/`
  # Equivalent to `/a{0,1}/`
  class QuestionMarkRepeater < BaseRepeater
    def initialize(group)
      super
      @min_repeats = 0
      @max_repeats = 1
    end
  end

  # When a range is used, e.g. `/a{1}/`, `/a{1,}/`, `/a{1,3}/`, `/a{,3}/`
  class RangeRepeater < BaseRepeater
    def initialize(group, min, has_comma, max)
      super(group)
      @min_repeats = min || 0
      @max_repeats = if !has_comma
                       @min_repeats
                     else
                       [
                         max,
                         @min_repeats + RegexpExamples::Config.max_repeater_variance
                       ].compact.min
                     end
    end
  end
end
