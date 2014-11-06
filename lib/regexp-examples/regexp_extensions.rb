class Regexp
module Examples
  def examples
    partial_examples =
      RegexpExamples::Parser.new(source)
        .parse
        .map {|repeater| repeater.result}
    partial_examples = RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(partial_examples)
    RegexpExamples::permutations_of_strings(partial_examples)
  end
end
  include Examples
end

