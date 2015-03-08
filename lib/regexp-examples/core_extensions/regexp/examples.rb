module CoreExtensions
  module Regexp
    module Examples
      def examples(**config_options)
        RegexpExamples::ResultCountLimiters.configure!(
          config_options[:max_repeater_variance],
          config_options[:max_group_results]
        )
        examples_by_method(:map_results)
      end

      def random_example(**config_options)
        RegexpExamples::ResultCountLimiters.configure!(
          config_options[:max_repeater_variance]
        )
        examples_by_method(:map_random_result).first
      end

      private
        def examples_by_method(method)
        full_examples = RegexpExamples.send(
          method,
          RegexpExamples::Parser.new(source, options).parse
        )
        RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
        end
    end
  end
end

# Regexp#include is private for ruby 2.0 and below
Regexp.send(:include, CoreExtensions::Regexp::Examples)

