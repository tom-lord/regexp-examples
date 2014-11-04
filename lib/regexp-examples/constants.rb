module RegexpExamples
  # Number of times to repeat for Star and Plus repeaters
  TIMES = 2

  # Set of chars for Dot and negated [^] char groups
  #CHARS = [("a".."z").to_a, ("A".."Z").to_a, ".", ",", ";"].flatten
  #TODO: Make these character sets more complete
  #e.g. Sets for \d, \w, \h, \s
  CHARS = %w{a b c d e}
end

