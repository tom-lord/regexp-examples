class Regexp
module Examples
  def examples
    partial_examples =
      RegexpExamples::Parser.new(source)
        .parse
        .map {|repeater| repeater.result}
    full_examples = RegexpExamples::permutations_of_strings(partial_examples.dup, no_join: true)
    full_examples_with_backrefs = \
      RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_examples)
    full_examples_with_backrefs.map(&:join)
  end
end
  include Examples
end

