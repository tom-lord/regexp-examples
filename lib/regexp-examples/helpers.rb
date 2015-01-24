module RegexpExamples
  # Given an array of arrays of strings,
  # returns all possible perutations,
  # for strings created by joining one
  # element from each array
  #
  # For example:
  # permutations_of_strings [ ['a'], ['b'], ['c', 'd', 'e'] ] #=> ['abc', 'abd', 'abe']
  # permutations_of_strings [ ['a', 'b'], ['c', 'd'] ] #=> [ 'ac', 'ad', 'bc', 'bd' ]
  def self.permutations_of_strings(arrays_of_strings)
    first = arrays_of_strings.shift
    return first if arrays_of_strings.empty?
    first.product( permutations_of_strings(arrays_of_strings) ).map do |result|
      join_preserving_capture_groups(result)
    end
  end

  def self.join_preserving_capture_groups(result)
    result.flatten!
    subgroups = result
      .map(&:all_subgroups)
      .flatten
    GroupResult.new(result.join, nil, subgroups)
  end

  def self.map_results(repeaters)
    repeaters
      .map {|repeater| repeater.result}
      .instance_eval do |partial_results|
        RegexpExamples::permutations_of_strings(partial_results)
      end
  end
end

