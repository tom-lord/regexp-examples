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

      # TODO: Can I make this more legible?
      # Ranges a-b
      # save first and last "-" if present
      first = nil
      last = nil
      first = @chars.shift if @chars.first == "-"
      last = @chars.pop if @chars.last == "-"
      while i = @chars.index("-")
        @chars[i-1..i+1] = (@chars[i-1]..@chars[i+1]).to_a
      end
      # restore them back
      @chars.unshift(first) if first
      @chars.push(last) if last
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
    attr_reader :group_num
    def initialize(groups, group_num)
      @groups = groups
      @group_num = group_num
    end

    # Generates the result of each contained group
    # and adds the filled group of each result to
    # itself
    def result
      strings = @groups.map {|group| group.result}
      result = RegexpExamples::permutations_of_strings(strings)
      result.each_with_index do |group, index|
        BackReferenceTracker.add_filled_group(@group_num, index, group)
      end
      result
    end
  end

  class MultiGroupEnd
    def result
      ['']
    end
  end

  class OrGroup
    def initialize(repeaters)
      @repeaters = repeaters
    end

    def result
      repeaters_results = @repeaters.map do |repeater|
        repeater.result
      end
      RegexpExamples::permutations_of_strings(repeaters_results)
    end
  end

  class BackReferenceGroup
    attr_reader :num
    def initialize(num)
      @num = num
    end

    def result
      ["__#{@num}__"]
    end
  end

end
