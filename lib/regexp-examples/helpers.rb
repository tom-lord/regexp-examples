module RegexpExamples
  # Given an array of arrays of strings,
  # returns all possible perutations,
  # for strings created by joining one
  # element from each array
  #
  # For example:
  # permutations_of_strings [ ['a'], ['b'], ['c', 'd', 'e'] ] #=> ['acb', 'abd', 'abe']
  # permutations_of_strings [ ['a', 'b'], ['c', 'd'] ] #=> [ 'ac', 'ad', 'bc', 'bd' ]
  def self.permutations_of_strings(arrays_of_strings, options={})
    first = arrays_of_strings.shift
    return first if arrays_of_strings.empty?
    first.product( permutations_of_strings(arrays_of_strings, options) ).map do |result|
      if options[:no_join]
        result.flatten
      else
        join_preserving_capture_groups(result)
      end
    end
  end

  def self.join_preserving_capture_groups(result)
    result.flatten!
    subgroups = result
      .select { |partial| partial.respond_to? :group_id }
      .map(&:all_subgroups)
      .flatten

    if subgroups.empty?
      result.join
    else
      CaptureGroupResult.new(nil, subgroups, result.join)
    end
  end
end

