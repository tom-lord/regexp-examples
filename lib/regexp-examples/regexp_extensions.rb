class Regexp
  module Examples
    def examples
      full_examples = RegexpExamples::map_results(
        RegexpExamples::Parser.new(source).parse
      )
      RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
    end
  end
  include Examples
end

