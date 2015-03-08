module RegexpExamples
  # Given an array of arrays of strings, returns all possible perutations
  # for strings, created by joining one element from each array
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

    # Only save the LAST group from repeated capture groups, e.g. /([ab]){2}/
    subgroups.delete_if do |subgroup|
      subgroups.count { |other_subgroup| other_subgroup.group_id == subgroup.group_id } > 1
    end
    GroupResult.new(result.join, nil, subgroups)
  end

  def self.map_results(repeaters)
    generic_map_result(repeaters, :result)
  end

  def self.map_random_result(repeaters)
    generic_map_result(repeaters, :random_result)
  end

  private
  def self.generic_map_result(repeaters, method)
    repeaters
      .map {|repeater| repeater.public_send(method)}
      .instance_eval do |partial_results|
        RegexpExamples.permutations_of_strings(partial_results)
      end
  end
end

