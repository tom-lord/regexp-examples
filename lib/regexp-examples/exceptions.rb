module RegexpExamples
  class Error < StandardError; end
  class UnsupportedSyntaxError < Error; end
  class IllegalSyntaxError < Error; end
  class BackrefNotFound < Error; end
end
