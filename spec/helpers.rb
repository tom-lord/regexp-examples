# Common helper methods, for lots of tests
# Included into the RSpec config, so accessible inside test blocks.
module Helpers
  def examples_exist(regexp, regexp_examples)
    expect(regexp_examples)
      .not_to be_empty, "No examples were generated for regexp: /#{regexp.source}/"
  end

  def examples_match(regexp, regexp_examples)
    # Note: /\A...\z/ is used to prevent misleading examples from passing the test.
    # For example, we don't want things like:
    # /a*/.examples to include "xyz"
    # /a|b/.examples to include "bad"
    regexp_examples.each do |example|
      expect(example).to match(/\A(?:#{regexp.source})\z/)
    end
  end
end
