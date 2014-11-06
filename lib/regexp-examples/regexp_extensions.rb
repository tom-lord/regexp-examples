class Regexp
module Examples
  def examples
    regexp_string = self.inspect[1..-2]
    partial_examples =
      RegexpExamples::Parser.new(regexp_string)
        .parse
        .map {|repeater| repeater.result}
    partial_examples = RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(partial_examples)
    RegexpExamples::permutations_of_strings(partial_examples)
  end
end
  include Examples
end

