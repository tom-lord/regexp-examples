# A common helper used throughout various parser methods
module RegexpExamples
  module CharsetNegationHelper
    def negate_if(charset, is_negative)
      is_negative ? (CharSets::Any.dup - charset) : charset
    end
  end
end
