module RegexpExamples
  # All Group#result methods return an array of GroupResult objects
  # The key objective here is to keep track of all capture groups, in order
  # to fill in backreferences
  class GroupResult < String
    attr_reader :group_id, :subgroups
    def initialize(result, group_id = nil, subgroups = [])
      @group_id = group_id
      @subgroups = subgroups
      if result.respond_to?(:group_id)
        @subgroups = result.all_subgroups
      end
      super(result)
    end

    def all_subgroups
      [self, subgroups].flatten.reject { |subgroup| subgroup.group_id.nil? }
    end

    def swapcase
      # Override to preserve subgroups
      GroupResult.new(super.to_s, group_id, subgroups)
    end
  end

  module ForceLazyEnumerators
    def force_if_lazy(arr_or_enum)
      arr_or_enum.respond_to?(:force) ? arr_or_enum.force : arr_or_enum
    end
  end

  module GroupWithIgnoreCase
    include ForceLazyEnumerators
    attr_reader :ignorecase
    def result
      group_result = super
      if ignorecase
        group_result_array = force_if_lazy(group_result)
        group_result_array
          .concat( group_result_array.map(&:swapcase) )
          .uniq
      else
        group_result
      end
    end
  end

  module RandomResultBySample
    include ForceLazyEnumerators
    def random_result
      force_if_lazy(result).sample(1)
    end
  end

  class SingleCharGroup
    include RandomResultBySample
    prepend GroupWithIgnoreCase
    def initialize(char, ignorecase)
      @char = char
      @ignorecase = ignorecase
    end
    def result
      [GroupResult.new(@char)]
    end
  end

  # Used as a workaround for when a group is expected to be returned,
  # but there are no results for the group.
  # i.e. PlaceHolderGroup.new.result == '' == SingleCharGroup.new('').result
  # (But using PlaceHolderGroup makes it clearer what the intention is!)
  class PlaceHolderGroup
    include RandomResultBySample
    def result
      [GroupResult.new('')]
    end
  end

  class CharGroup
    include RandomResultBySample
    prepend GroupWithIgnoreCase
    def initialize(chars, ignorecase)
      @chars = chars
      @ignorecase = ignorecase
    end

    def result
      @chars.lazy.map do |result|
        GroupResult.new(result)
      end
    end

  end

  class DotGroup
    include RandomResultBySample
    attr_reader :multiline
    def initialize(multiline)
      @multiline = multiline
    end

    def result
      chars = multiline ? CharSets::Any : CharSets::AnyNoNewLine
      chars.lazy.map do |result|
        GroupResult.new(result)
      end
    end
  end

  class MultiGroup
    attr_reader :group_id
    def initialize(groups, group_id)
      @groups = groups
      @group_id = group_id
    end

    def result
      result_by_method(:result)
    end

    def random_result
      result_by_method(:random_result)
    end

    private
    # Generates the result of each contained group
    # and adds the filled group of each result to itself
    def result_by_method(method)
      strings = @groups.map {|repeater| repeater.public_send(method)}
      RegexpExamples.permutations_of_strings(strings).map do |result|
        GroupResult.new(result, group_id)
      end
    end
  end

  class OrGroup
    def initialize(left_repeaters, right_repeaters)
      @left_repeaters = left_repeaters
      @right_repeaters = right_repeaters
    end

    def result
      result_by_method(:map_results)
    end

    def random_result
      # TODO: This logic is flawed in terms of choosing a truly "random" example!
      # E.g. /a|b|c|d/.random_example will choose a letter with the following probabilities:
      # a = 50%, b = 25%, c = 12.5%, d = 12.5%
      # In order to fix this, I must either apply some weighted selection logic,
      # or change how the OrGroup examples are generated - i.e. make this class work with >2 repeaters
      result_by_method(:map_random_result).sample(1)
    end

    private
    def result_by_method(method)
      left_result = RegexpExamples.public_send(method, @left_repeaters)
      right_result = RegexpExamples.public_send(method, @right_repeaters)
      left_result.concat(right_result).flatten.uniq.map do |result|
        GroupResult.new(result)
      end
    end
  end

  class BackReferenceGroup
    include RandomResultBySample
    attr_reader :id
    def initialize(id)
      @id = id
    end

    def result
      [ GroupResult.new("__#{@id}__") ]
    end
  end

end
