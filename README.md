# regexp-examples
[![Gem Version](https://badge.fury.io/rb/regexp-examples.svg)](http://badge.fury.io/rb/regexp-examples)
[![Build Status](https://travis-ci.org/tom-lord/regexp-examples.svg?branch=master)](https://travis-ci.org/tom-lord/regexp-examples/builds)
![Code Coverage](coverage/coverage-badge.png)

Extends the Regexp class with the method: Regexp#examples

This method generates a list of (some\*) strings that will match the given regular expression

\* If the regex has an infinite number of possible srings that match it, such as `/a*b+c{2,}/`,
or a huge number of possible matches, such as `/.\w/`, then only a subset of these will be listed.

For more detail on this, see [configuration options](#configuration-options).

## Usage

```ruby
/a*/.examples #=> [''. 'a', 'aa']
/ab+/.examples #=> ['ab', 'abb', 'abbb']
/this|is|awesome/.examples #=> ['this', 'is', 'awesome']
/https?:\/\/(www\.)?github\.com/.examples #=> ['http://github.com',
  # 'http://www.github.com', 'https://github.com', 'https://www.github.com']
/(I(N(C(E(P(T(I(O(N)))))))))*/.examples #=> ["", "INCEPTION", "INCEPTIONINCEPTION"]
/\x74\x68\x69\x73/.examples #=> ["this"]
/\u6829/.examples #=> ["栩"]
/what about (backreferences\?) \1/.examples #=> ['what about backreferences? backreferences?']
```

## Supported syntax

* All forms of repeaters (quantifiers), e.g. `/a*/`, `/a+/`, `/a?/`, `/a{1,4}/`, `/a{3,}/`, `/a{,2}/`
  * Reluctant and possissive repeaters work fine, too - e.g. `/a*?/`, `/a*+/`
* Boolean "Or" groups, e.g. `/a|b|c/`
* Character sets (inluding ranges and negation!), e.g. `/[abc]/`, `/[A-Z0-9]/`, `/[^a-z]/`, `/[\w\s\b]/`
* Escaped characters, e.g. `/\n/`, `/\w/`, `/\D/` (and so on...)
* Capture groups, e.g. `/(group)/`
  * Including named groups, e.g. `/(?<name>group)/`
  * ...And backreferences(!!!), e.g. `/(this|that) \1/` `/(?<name>foo) \k<name>/`
  * Groups work fine, even if nested or optional e.g. `/(even(this(works?))) \1 \2 \3/`, `/what about (this)? \1/`
  * Non-capture groups, e.g. `/(?:foo)/`
  * Comment groups, e.g. `/foo(?#comment)bar/`
* Control characters, e.g. `/\ca/`, `/\cZ/`, `/\C-9/`
* Escape sequences, e.g. `/\x42/`, `/\x5word/`, `/#{"\x80".force_encoding("ASCII-8BIT")}/`
* Unicode characters, e.g. `/\u0123/`, `/\uabcd/`, `/\u{789}/`
* **Arbitrarily complex combinations of all the above!**

* Regexp options can also be used:
  * Case insensitive examples: `/cool/i.examples #=> ["cool", "cooL", "coOl", "coOL", ...]`
  * Multiline examples: `/./m.examples(max_group_results: 999) #=> ["a", "b", "c", ..., "\n"]`
  * Extended form examples: `/line1 #comment \n line2/x.examples #=> ["line1line2"]`
  * Options toggling supported: `/before(?imx-imx)after/`, `/before(?imx-imx:subexpr)after/`

## Bugs and Not-Yet-Supported syntax

* Nested character classes, and the use of set intersection ([See here](http://www.ruby-doc.org/core-2.2.0/Regexp.html#class-Regexp-label-Character+Classes) for the official documentation on this.) For example:
  * `/[[abc]]/.examples`  (which _should_ return `["a", "b", "c"]`)
  * `/[[a-d]&&[c-f]]/.examples` (which _should_ return: `["c", "d"]`)

* Conditional capture groups, such as `/(group1) (?(1)yes|no)`

* The patterns: `/\10/` ... `/\77/` should match the octal representation of their character code, if there is no nth grouped subexpression. For example, `/\10/.examples` should return `["\x08"]`. Funnily enough, I did not think of this when writing my regexp parser.

Using any of the following will raise a RegexpExamples::UnsupportedSyntax exception (until such time as they are implemented!):

* POSIX bracket expressions, e.g. `/[[:alnum:]]/`, `/[[:space:]]/`
* Named properties, e.g. `/\p{L}/` ("Letter"), `/\p{Arabic}/` ("Arabic character"), `/\p{^Ll}/` ("Not a lowercase letter")
* Subexpression calls, e.g. `/(?<name> ... \g<name>* )/` (Note: These could get _really_ ugly to implement, and may even be impossible, so I highly doubt it's worth the effort!)

There are loads more (increasingly obscure) unsupported bits of syntax, which I cannot be bothered to write out here. Full documentation on all the various other obscurities in the ruby (version 2.x) regexp parser can be found [here](https://raw.githubusercontent.com/k-takata/Onigmo/master/doc/RE).

## Impossible features ("illegal syntax")

The following features in the regex language can never be properly implemented into this gem because, put simply, they are not technically "regular"!
If you'd like to understand this in more detail, there are many good blog posts out on the internet. The [wikipedia entry](http://en.wikipedia.org/wiki/Regular_expression)'s not bad either.

Using any of the following will raise a RegexpExamples::IllegalSyntax exception:

* Lookarounds, e.g. `/foo(?=bar)/`, `/foo(?!bar)/`, `/(?<=foo)bar/`, `/(?<!foo)bar/`
* [Anchors](http://ruby-doc.org/core-2.2.0/Regexp.html#class-Regexp-label-Anchors) (`\b`, `\B`, `\G`, `^`, `\A`, `$`, `\z`, `\Z`), e.g. `/\bword\b/`, `/line1\n^line2/`
  * However, a special case has been made to allow `^` and `\A` at the start of a pattern; and to allow `$`, `\z` and `\Z` at the end of pattern. In such cases, the characters are effectively just ignored.

(Note: Backreferences are not really "regular" either, but I got these to work with a bit of hackery!)

##Configuration Options

When generating examples, the gem uses 2 configurable values to limit how many examples are listed:

* `max_repeater_variance` (default = `2`) restricts how many examples to return for each repeater. For example:
  * `.*` is equivalent to `.{0,2}`
  * `.+` is equivalent to `.{1,3}`
  * `.{2,}` is equivalent to `.{2,4}`
  * `.{,3}` is equivalent to `.{0,2}`
  * `.{3,8}` is equivalent to `.{3,5}`

* `max_group_results` (default = `5`) restricts how many characters to return for each "set". For example:
  * `\d` is equivalent to `[01234]`
  * `\w` is equivalent to `[abcde]`
  * `[h-s]` is equivalent to `[hijkl]`
  * `(1|2|3|4|5|6|7|8)` is equivalent to `[12345]`

To use an alternative value, simply pass the configuration option as follows:

```ruby
/a*/.examples(max_repeater_variance: 5)
  #=> [''. 'a', 'aa', 'aaa', 'aaaa' 'aaaaa']
/[F-X]/.examples(max_group_results: 10)
  #=> ['F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O']
```

_**WARNING**: Choosing huge numbers, along with a "complex" regex, could easily cause your system to freeze!_

For example, if you try to generate a list of _all_ 5-letter words: `/\w{5}/.examples(max_group_results: 999)`, then since there are actually `63` "word" characters (upper/lower case letters, numbers and "\_"), this will try to generate `63**5 #=> 992436543` (almost 1 _trillion_) examples!

In other words, think twice before playing around with this config!

A more sensible use case might be, for example, to generate one random 1-4 digit string:

`/\d{1,4}/.examples(max_repeater_variance: 3, max_group_results: 10).sample(1)`

(Note: I may develop a much more efficient way to "generate one example" in a later release of this gem.)

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
