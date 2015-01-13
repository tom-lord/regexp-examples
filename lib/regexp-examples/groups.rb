module RegexpExamples
  class SingleCharGroup
    def initialize(char)
      @char = char
    end
    def result
      [@char]
    end
  end

  class CharGroup
    def initialize(chars)
      @chars = chars
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
      # Replace all instances of e.g. ["a" "-" "z"] with ["a", "b", ..., "z"]
      while i = @chars.index("-")
        @chars[i-1..i+1] = (@chars[i-1]..@chars[i+1]).to_a
      end
      # restore them back
      @chars.unshift(first) if first
      @chars.push(last) if last
    end

    def init_backslash_chars
      @chars.each_with_index do |char, i|
        if char == "\\"
          if BackslashCharMap.keys.include?(@chars[i+1])
            @chars[i..i+1] = BackslashCharMap[@chars[i+1]]
          elsif @chars[i+1] == "\\"
            @chars.delete_at(i+1)
          else
            @chars.delete_at(i)
          end
        end
      end
    end

    def result
      if @negative
        CharSets::Any - @chars
      else
        @chars
      end
    end
  end

  class DotGroup
    def result
      CharSets::Any
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
      RegexpExamples::permutations_of_strings(strings).map do |result|
        subgroups = result.respond_to?(:group_id) ? result.all_subgroups : []
        group_id ? CaptureGroupResult.new(group_id, subgroups, result) : result
      end
    end
  end

  class MultiGroupEnd
    def result
      ['']
    end
  end

  class OrGroup
    def initialize(left_repeaters, right_repeaters)
      @left_repeaters = left_repeaters
      @right_repeaters = right_repeaters
    end

    def result
      left_result = @left_repeaters.map do |repeater|
        RegexpExamples::permutations_of_strings([repeater.result])
      end
      right_result = @right_repeaters.map do |repeater|
        RegexpExamples::permutations_of_strings([repeater.result])
      end
      left_result.concat(right_result).flatten.uniq
    end
  end

  class BackReferenceGroup
    attr_reader :id
    def initialize(id)
      @id = id
    end

    def result
      ["__#{@id}__"]
    end
  end

end
