# :nodoc:
module RegexpExamples
  # Configuration settings to limit the number/length of Regexp examples generated
  class Config
    # The maximum variance for any given repeater, to prevent a huge/infinite number of
    # examples from being listed. For example, if self.max_repeater_variance = 2 then:
    # .* is equivalent to .{0,2}
    # .+ is equivalent to .{1,3}
    # .{2,} is equivalent to .{2,4}
    # .{,3} is equivalent to .{0,2}
    # .{3,8} is equivalent to .{3,5}
    MAX_REPEATER_VARIANCE_DEFAULT = 2

    # Maximum number of characters returned from a char set, to reduce output spam
    # For example, if self.max_group_results = 5 then:
    # \d is equivalent to [01234]
    # \w is equivalent to [abcde]
    MAX_GROUP_RESULTS_DEFAULT = 5

    # Maximum number of results to be generated, for Regexp#examples
    # This is to prevent the system "freezing" when given instructions like:
    # /[ab]{30}/.examples
    # (Which would attempt to generate 2**30 == 1073741824 examples!!!)
    MAX_RESULTS_LIMIT_DEFAULT = 10_000
    class << self
      def with_configuration(**new_config)
        original_config = config.dup

        begin
          update_config(**new_config)
          result = yield
        ensure
          update_config(**original_config)
        end

        result
      end

      # Thread-safe getters and setters
      %i[max_repeater_variance max_group_results max_results_limit].each do |m|
        define_method(m) do
          config[m]
        end
        define_method("#{m}=") do |value|
          config[m] = value
        end
      end

      private

      def update_config(**args)
        Thread.current[:regexp_examples_config].merge!(args)
      end

      def config
        Thread.current[:regexp_examples_config] ||= {
          max_repeater_variance: MAX_REPEATER_VARIANCE_DEFAULT,
          max_group_results: MAX_GROUP_RESULTS_DEFAULT,
          max_results_limit: MAX_RESULTS_LIMIT_DEFAULT
        }
      end
    end
  end
end
