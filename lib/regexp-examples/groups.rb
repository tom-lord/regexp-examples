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

  class CharGroup
    prepend GroupWithIgnoreCase
    def initialize(chars, ignorecase)
      @chars = chars
      @ignorecase = ignorecase
      if chars[0] == "^"
        @negative = true
        @chars = @chars[1..-1]
      else
        @negative = false
      end

      init_backslash_chars
      init_ranges
    end

    def init_ranges
      # save first and last "-" if present

      first = nil
      last = nil
      first = @chars.shift if @chars.first == "-"
      last = @chars.pop if @chars.last == "-"
      # Replace all instances of e.g. ["a", "-", "z"] with ["a", "b", ..., "z"]
      while i = @chars.index("-")
        # Prevent infinite loops from expanding [",", "-", "."] to itself
        # (Since ",".ord = 44, "-".ord = 45, ".".ord = 46)
        if (@chars[i-1] == ',' && @chars[i+1] == '.')
          first = '-'
          @chars.delete_at(i)
        else
          @chars[i-1..i+1] = (@chars[i-1]..@chars[i+1]).to_a
        end
      end
      # restore them back
      @chars.unshift(first) if first
      @chars.push(last) if last
    end

    def init_backslash_chars
      @chars.each_with_index do |char, i|
        if char == "\\"
          if BackslashCharMap.keys.include?(@chars[i+1])
            @chars[i..i+1] = move_backslash_to_front( BackslashCharMap[@chars[i+1]] )
          elsif @chars[i+1] == 'b'
            @chars[i..i+1] = "\b"
          elsif @chars[i+1] == "\\"
            @chars.delete_at(i+1)
          else
            @chars.delete_at(i)
          end
        end
      end
    end

    def result
      (@negative ? (CharSets::Any - @chars) : @chars).map do |result|
        GroupResult.new(result)
      end
    end

    private
    def move_backslash_to_front(chars)
      if index = chars.index { |char| char == '\\' }
        chars.unshift chars.delete_at(index)
      end
      chars
    end
  end

  class DotGroup
    attr_reader :multiline
    def initialize(multiline)
      @multiline = multiline
    end

    def result
      chars = CharSets::Any
      chars = (["\n"] | chars) if multiline
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
