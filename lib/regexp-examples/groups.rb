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

  module GroupWithIgnoreCase
    attr_reader :ignorecase
    def result
      group_result = super
      if ignorecase
        group_result
          .concat( group_result.map(&:swapcase) )
          .uniq
      else
        group_result
      end
    end
  end

  class SingleCharGroup
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
    def result
      [GroupResult.new('')]
    end
  end

  class CharGroup
    prepend GroupWithIgnoreCase
    def initialize(chars, ignorecase)
      @chars = chars
      @ignorecase = ignorecase
    end

    def result
      @chars.map do |result|
        GroupResult.new(result)
      end
    end

  end

  class DotGroup
    attr_reader :multiline
    def initialize(multiline)
      @multiline = multiline
    end

    def result
      chars = multiline ? CharSets::Any : CharSets::AnyNoNewLine
      chars.map do |result|
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

    # Generates the result of each contained group
    # and adds the filled group of each result to
    # itself
    def result
      strings = @groups.map {|repeater| repeater.result}
      RegexpExamples.permutations_of_strings(strings).map do |result|
        GroupResult.new(result, group_id)
      end
    end
  end

  class MultiGroupEnd
  end

  class OrGroup
    def initialize(left_repeaters, right_repeaters)
      @left_repeaters = left_repeaters
      @right_repeaters = right_repeaters
    end


    def result
      left_result = RegexpExamples.map_results(@left_repeaters)
      right_result = RegexpExamples.map_results(@right_repeaters)
      left_result.concat(right_result).flatten.uniq.map do |result|
        GroupResult.new(result)
      end
    end
  end

  class BackReferenceGroup
    attr_reader :id
    def initialize(id)
      @id = id
    end

    def result
      [ GroupResult.new("__#{@id}__") ]
    end
  end

end
