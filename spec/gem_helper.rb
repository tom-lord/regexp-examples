require 'spec_helper'

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
end
