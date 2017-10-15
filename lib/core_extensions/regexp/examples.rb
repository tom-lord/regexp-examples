module CoreExtensions
  module Regexp
    # A wrapper module to namespace/isolate the Regexp#examples and Regexp#random_example
    # monkey patches.
    # No core classes are extended in any way, other than the above two methods.
    module Examples
      def examples(**config_options)
        RegexpExamples::Config.with_configuration(config_options) do
          examples_by_method(:result)
        end
      end

      def random_example(**config_options)
        RegexpExamples::Config.with_configuration(config_options) do
          examples_by_method(:random_result).sample
        end
      end

      private

      def examples_by_method(method)
        full_examples = RegexpExamples.generic_map_result(
          RegexpExamples::Parser.new(source, options).parse,
          method
        )
        RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
      end
    end
  end
end

# Regexp#include is private for ruby 2.0 and below
Regexp.send(:include, CoreExtensions::Regexp::Examples)
