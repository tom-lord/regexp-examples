require 'coveralls'
Coveralls.wear!

require './lib/regexp-examples.rb'
require 'helpers'
require 'pry'

# Several of these tests (intentionally) use "weird" regex patterns,
# that spam annoying warnings when running.
# E.g. warning: invalid back reference: /\k/
# and  warning: character class has ']' without escape: /[]]/
# This config disables those warnings.
$VERBOSE = nil

RSpec.configure do |config|
  config.include Helpers

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10
end
