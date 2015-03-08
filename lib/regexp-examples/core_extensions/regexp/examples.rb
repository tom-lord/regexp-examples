module CoreExtensions
  module Regexp
    module Examples
      def examples(config_options={})
        full_examples = RegexpExamples.map_results(
          RegexpExamples::Parser.new(source, options, config_options).parse
        )
        RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
      end

      def random_example
        full_examples = RegexpExamples.map_random_result(
          RegexpExamples::Parser.new(source, options, max_group_results: 1000000).parse
        )
        RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples).first
      end
    end
  end
end

# Regexp#include is private for ruby 2.0 and below
Regexp.send(:include, CoreExtensions::Regexp::Examples)

