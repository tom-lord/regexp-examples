# regexp-examples
[![Gem Version](https://badge.fury.io/rb/regexp-examples.svg)](http://badge.fury.io/rb/regexp-examples)

Extends the Regexp class with the method: Regexp#examples

This method generates a list of (some\*) strings that will match the given regular expression

\* If the regex has an infinite number of possible srings that match it, such as `/a*b+c{2,}/`,
or a huge number of possible matches, such as `/.\w/`, then only a subset of these will be listed.

## Usage

```ruby
/a*/.examples #=> [''. 'a', 'aa']
/b+/.examples #=> ['b', 'bb']
/this|is|awesome/.examples #=> ['this', 'is', 'awesome']
/foo-.{1,}-bar/.examples #=> ['foo-a-bar', 'foo-b-bar', 'foo-c-bar', 'foo-d-bar', 'foo-e-bar',
  # 'foo-aa-bar', 'foo-bb-bar', 'foo-cc-bar', 'foo-dd-bar', 'foo-ee-bar', 'foo-aaa-bar', 'foo-bbb-bar',
  # 'foo-ccc-bar', 'foo-ddd-bar', 'foo-eee-bar']
/https?:\/\/(www\.)?github\.com/.examples #=> ['http://github.com',
  # 'http://www.github.com', 'https://github.com', 'https://www.github.com']
/(I(N(C(E(P(T(I(O(N)))))))))*/.examples #=> ["", "INCEPTION", "INCEPTIONINCEPTION"]
/what about (backreferences\?) \1/.examples #=> ['what about backreferences? backreferences?']
```

The current version is still very much under development, and contains various bugs/missing features...
However, when completed, this will hopefully work for ALL regular expressions, *except for lookarounds*!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regexp-examples'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regexp-examples

## Contributing

1. Fork it ( https://github.com/[my-github-username]/regexp-examples/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
6. Don't forget to add tests!!
