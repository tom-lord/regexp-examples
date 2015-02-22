module RegexpExamples
  # Given an array of chars from inside a character set,
  # Interprets all backslashes, ranges and negations
  # TODO: This needs a bit of a rewrite because:
  #   A) It's ugly
  #   B) It doesn't take into account nested character groups, or set intersection
  # To achieve this, the algorithm needs to be recursive, like the main Parser.
  class ChargroupParser
    def initialize(chars)
      @chars = chars
      if @chars[0] == "^"
        @negative = true
        @chars = @chars[1..-1]
      else
        @negative = false
      end

      init_backslash_chars
      init_ranges
    end

    def result
      @negative ? (CharSets::Any - @chars) : @chars
    end

    private
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

    def init_ranges
      # remove hyphen ("-") from front/back, if present
      hyphen = nil
      hyphen = @chars.shift if @chars.first == "-"
      hyphen ||= @chars.pop if @chars.last == "-"
      # Replace all instances of e.g. ["a", "-", "z"] with ["a", "b", ..., "z"]
      while i = @chars.index("-")
        # Prevent infinite loops from expanding [",", "-", "."] to itself
        # (Since ",".ord = 44, "-".ord = 45, ".".ord = 46)
        if (@chars[i-1] == ',' && @chars[i+1] == '.')
          hyphen = @chars.delete_at(i)
        else
          @chars[i-1..i+1] = (@chars[i-1]..@chars[i+1]).to_a
        end
      end
      # restore hyphen, if stripped out earlier
      @chars.unshift(hyphen) if hyphen
    end

    def move_backslash_to_front(chars)
      if index = chars.index { |char| char == '\\' }
        chars.unshift chars.delete_at(index)
      end
      chars
    end
  end
end

