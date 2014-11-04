class Regexp
module Examples
  def examples
    regexp_string = self.inspect[1..-2]
    partial_examples =
      RegexpExamples::Parser.new(regexp_string)
        .parse
        .map {|repeater| repeater.result}
    full_examples = RegexpExamples::permutations_of_strings(partial_examples)
    full_examples.map{ |full_example| RegexpExamples::BackReferenceReplacer.new.substitute_backreferences(full_example)}
    full_examples
  end
end
  include Examples
end

