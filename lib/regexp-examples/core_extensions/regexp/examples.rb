module CoreExtensions
  module Regexp
    module Examples
      def examples(options={})
        full_examples = RegexpExamples.map_results(
          RegexpExamples::Parser.new(source, options).parse
        )
        RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
      end
    end
  end
end

# Regexp#include is private for ruby 2.0 and below
Regexp.send(:include, CoreExtensions::Regexp::Examples)

