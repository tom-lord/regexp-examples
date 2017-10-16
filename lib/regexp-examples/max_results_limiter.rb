module RegexpExamples
  # Abstract (base) class to assist limiting Regexp.examples max results
  class MaxResultsLimiter
    def initialize(initial_results_count)
      @results_count = initial_results_count
    end

    private

    # limiter_method and cumulator_method must be inverses
    # i.e. :- and :+, or :/ and :*
    def limit_results(partial_results, limiter_method, cumulator_method)
      return [] if partial_results.empty? # guard clause
      results_allowed = results_allowed_from(partial_results, limiter_method)
      cumulate_total(results_allowed.length, cumulator_method)
      results_allowed
    end

    def cumulate_total(new_results_count, cumulator_method)
      @results_count = if @results_count.zero?
                         new_results_count
                       else
                         @results_count.public_send(cumulator_method, new_results_count)
                       end
    end

    def results_allowed_from(partial_results, limiter_method)
      partial_results.first(
        RegexpExamples::Config.max_results_limit
          .public_send(limiter_method, @results_count)
      )
    end
  end

  # For example:
  # Needed when generating examples for /[ab]{10}/
  # (here, results_count will reach 2**10 == 1024)
  class MaxResultsLimiterByProduct < MaxResultsLimiter
    def initialize
      super(1)
    end

    def limit_results(partial_results)
      super(partial_results, :/, :*)
    end
  end

  # For example:
  # Needed when generating examples for /[ab]{10}|{cd}{11}/
  # (here, results_count will reach 1024 + 2048 == 3072)
  class MaxResultsLimiterBySum < MaxResultsLimiter
    def initialize
      super(0)
    end

    def limit_results(partial_results)
      super(partial_results, :-, :+)
    end
  end
end
