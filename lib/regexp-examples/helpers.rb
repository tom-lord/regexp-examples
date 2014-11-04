module RegexpExamples
  # Given an array of arrays of strings,
  # returns all possible perutations,
  # for strings created by joining one
  # element from each array
  #
  # For example:
  # permutations_of_strings [ ['a'], ['b'], ['c', 'd', 'e'] ] #=> ['acb', 'abd', 'abe']
  # permutations_of_strings [ ['a', 'b'], ['c', 'd'] ] #=> [ 'ac', 'ad', 'bc', 'bd' ]
  def self.permutations_of_strings(arrays_of_strings)
    return arrays_of_strings[0] if arrays_of_strings.size == 1
    first = arrays_of_strings.shift
    first.product( permutations_of_strings(arrays_of_strings) ).map {|x| x.flatten.join}
  end

  # TODO: For debugging only!! Delete this before v1.0
  def self.show(regexp)
    s = regexp.examples
    puts "#{regexp.inspect} --> #{s.inspect}"
    puts "Checking..."
    errors = s.reject {|string| string =~ regexp}
    if errors.size == 0
      puts "All strings match"
    else
      puts "These don't match: #{errors.inspect}"
    end
  end
end

