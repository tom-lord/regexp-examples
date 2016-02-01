# :nodoc:
module RegexpExamples
  # Given an array of arrays of strings, returns all possible perutations
  # for strings, created by joining one element from each array
  #
  # For example:
  # permutations_of_strings [ ['a'], ['b'], ['c', 'd', 'e'] ] #=> ['abc', 'abd', 'abe']
  # permutations_of_strings [ ['a', 'b'], ['c', 'd'] ] #=> [ 'ac', 'ad', 'bc', 'bd' ]
  #
  # Edge case:
  # permutations_of_strings [ [] ] #=> nil
  # (For example, ths occurs during /[^\d\D]/.examples #=> [])
  def self.permutations_of_strings(arrays_of_strings, max_results_limiter = MaxResultsLimiterByProduct.new)
    partial_result = max_results_limiter.limit_results(arrays_of_strings.shift)
    return partial_result if arrays_of_strings.empty?
    partial_result.product(permutations_of_strings(arrays_of_strings, max_results_limiter)).map do |result|
      join_preserving_capture_groups(result)
    end
  end

  def self.join_preserving_capture_groups(result)
    # Only save the LAST group from repeated capture groups, e.g. /([ab]){2}/
    # (Hence the need for "reverse"!)
    subgroups = result
                .flat_map(&:all_subgroups)
                .reverse
                .uniq(&:group_id)

    GroupResult.new(result.join, nil, subgroups)
  end

  def self.generic_map_result(repeaters, method)
    permutations_of_strings(
      repeaters.map { |repeater| repeater.public_send(method) }
    )
  end
end
