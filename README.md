# regexp-examples
[![Gem Version](https://badge.fury.io/rb/regexp-examples.svg)](http://badge.fury.io/rb/regexp-examples)
[![Build Status](https://travis-ci.org/tom-lord/regexp-examples.svg?branch=master)](https://travis-ci.org/tom-lord/regexp-examples/builds)
[![Coverage Status](https://coveralls.io/repos/tom-lord/regexp-examples/badge.svg?branch=master)](https://coveralls.io/r/tom-lord/regexp-examples?branch=master)

Extends the Regexp class with the methods: `Regexp#examples` and `Regexp#random_example`

`Regexp#examples` generates a list of all\* strings that will match the given regular expression.

`Regexp#random_example` returns one, random string (from all possible strings!!) that matches the regex.

\* If the regex has an infinite number of possible srings that match it, such as `/a*b+c{2,}/`,
or a huge number of possible matches, such as `/.\w/`, then only a subset of these will be listed.

For more detail on this, see [configuration options](#configuration-options).

If you'd like to understand how/why this gem works, please check out my [blog post](http://tom-lord.weebly.com/blog/reverse-engineering-regular-expressions) about it!

## Usage

```ruby
/a*/.examples #=> ['', 'a', 'aa']
/ab+/.examples #=> ['ab', 'abb', 'abbb']
/this|is|awesome/.examples #=> ['this', 'is', 'awesome']
/https?:\/\/(www\.)?github\.com/.examples #=> ['http://github.com',
  # 'http://www.github.com', 'https://github.com', 'https://www.github.com']
/(I(N(C(E(P(T(I(O(N)))))))))*/.examples #=> ["", "INCEPTION", "INCEPTIONINCEPTION"]
/\x74\x68\x69\x73/.examples #=> ["this"]
/what about (backreferences\?) \1/.examples
  #=> ['what about backreferences? backreferences?']
/
  \u{28}\u2022\u{5f}\u2022\u{29}
  |
  \u{28}\u{20}\u2022\u{5f}\u2022\u{29}\u{3e}\u2310\u25a0\u{2d}\u25a0\u{20}
  |
  \u{28}\u2310\u25a0\u{5f}\u25a0\u{29}
/x.examples #=> ["(•_•)", "( •_•)>⌐■-■ ", "(⌐■_■)"]

###################################################################################

# Obviously, you will get different results if you try these yourself!
/\w{10}@(hotmail|gmail)\.com/.random_example #=> "TTsJsiwzKS@gmail.com"
/\p{Greek}{80}/.random_example
  #=> "ΖΆΧͷᵦμͷηϒϰΟᵝΔ΄θϔζΌψΨεκᴪΓΕπι϶ονϵΓϹᵦΟπᵡήϴϜΦϚϴϑ͵ϴΉϺ͵ϹϰϡᵠϝΤΏΨϹϊϻαώΞΰϰΑͼΈΘͽϙͽξΆΆΡΡΉΓς"
/written by tom lord/i.random_example #=> "WrITtEN bY tOM LORD"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regexp-examples'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regexp-examples

## Supported syntax

Short answer: **Everything** is supported, apart from "irregular" aspects of the regexp language -- see [impossible features](#impossible-features-illegal-syntax).

Long answer:

* All forms of repeaters (quantifiers), e.g. `/a*/`, `/a+/`, `/a?/`, `/a{1,4}/`, `/a{3,}/`, `/a{,2}/`
  * Reluctant and possissive repeaters work fine, too, e.g. `/a*?/`, `/a*+/`
* Boolean "Or" groups, e.g. `/a|b|c/`
* Character sets, e.g. `/[abc]/` - including:
  * Ranges, e.g.`/[A-Z0-9]/`
  * Negation, e.g. `/[^a-z]/`
  * Escaped characters, e.g. `/[\w\s\b]/`
  * POSIX bracket expressions, e.g. `/[[:alnum:]]/`, `/[[:^space:]]/`
  * Set intersection, e.g. `/[[a-h]&&[f-z]]/`
* Escaped characters, e.g. `/\n/`, `/\w/`, `/\D/` (and so on...)
* Capture groups, e.g. `/(group)/`
  * Including named groups, e.g. `/(?<name>group)/`
  * And backreferences(!!!), e.g. `/(this|that) \1/` `/(?<name>foo) \k<name>/`
  * ...even for the more "obscure" syntax, e.g. `/(?<future>the) \k'future'/`, `/(a)(b) \k<-1>/``
  * ...and even if nested or optional, e.g. `/(even(this(works?))) \1 \2 \3/`, `/what about (this)? \1/`
  * Non-capture groups, e.g. `/(?:foo)/`
  * Comment groups, e.g. `/foo(?#comment)bar/`
* Control characters, e.g. `/\ca/`, `/\cZ/`, `/\C-9/`
* Escape sequences, e.g. `/\x42/`, `/\x5word/`, `/#{"\x80".force_encoding("ASCII-8BIT")}/`
* Unicode characters, e.g. `/\u0123/`, `/\uabcd/`, `/\u{789}/`
* Octal characters, e.g. `/\10/`, `/\177/`
* Named properties, e.g. `/\p{L}/` ("Letter"), `/\p{Arabic}/` ("Arabic character")
, `/\p{^Ll}/` ("Not a lowercase letter"), `/\P{^Canadian_Aboriginal}/` ("Not not a Canadian aboriginal character")
* **Arbitrarily complex combinations of all the above!**

* Regexp options can also be used:
  * Case insensitive examples: `/cool/i.examples #=> ["cool", "cooL", "coOl", "coOL", ...]`
  * Multiline examples: `/./m.examples #=> ["\n", "a", "b", "c", "d"]`
  * Extended form examples: `/line1 #comment \n line2/x.examples #=> ["line1line2"]`
  * Options toggling supported: `/before(?imx-imx)after/`, `/before(?imx-imx:subexpr)after/`

## Bugs and Not-Yet-Supported syntax

* There are some (rare) edge cases where backreferences do not work properly, e.g. `/(a*)a* \1/.examples` - which includes "aaaa aa". This is because each repeater is not context-aware, so the "greediness" logic is flawed. (E.g. in this case, the second `a*` should always evaluate to an empty string, because the previous `a*` was greedy!) However, patterns like this are highly unusual...
* Some named properties, e.g. `/\p{Arabic}/`, list non-matching examples for ruby 2.0/2.1 (as the definitions changed in ruby 2.2). This will be fixed in version 1.1.1 (see the pending pull request)!

Since the Regexp language is so vast, it's quite likely I've missed something (please raise an issue if you find something)! The only missing feature that I'm currently aware of is:
* Conditional capture groups, e.g. `/(group1)? (?(1)yes|no)/.examples` (which *should* return: `["group1 yes", " no"]`)

Some of the most obscure regexp features are not even mentioned in the ruby docs! However, full documentation on all the intricate obscurities in the ruby (version 2.x) regexp parser can be found [here](https://raw.githubusercontent.com/k-takata/Onigmo/master/doc/RE).

## Impossible features ("illegal syntax")

The following features in the regex language can never be properly implemented into this gem because, put simply, they are not technically "regular"!
If you'd like to understand this in more detail, check out what I had to say in [my blog post](http://tom-lord.weebly.com/blog/reverse-engineering-regular-expressions) about this gem!

Using any of the following will raise a RegexpExamples::IllegalSyntax exception:

* Lookarounds, e.g. `/foo(?=bar)/`, `/foo(?!bar)/`, `/(?<=foo)bar/`, `/(?<!foo)bar/`
* [Anchors](http://ruby-doc.org/core-2.2.0/Regexp.html#class-Regexp-label-Anchors) (`\b`, `\B`, `\G`, `^`, `\A`, `$`, `\z`, `\Z`), e.g. `/\bword\b/`, `/line1\n^line2/`
  * However, a special case has been made to allow `^`, `\A` and `\G` at the start of a pattern; and to allow `$`, `\z` and `\Z` at the end of pattern. In such cases, the characters are effectively just ignored.
* Subexpression calls (`\g`), e.g. `/(?<name> ... \g<name>* )/`

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

`Rexexp#examples` makes use of *both* these options; `Rexexp#random_example` only uses `max_repeater_variance`, since the other option is redundant!

To use an alternative value, simply pass the configuration option as follows:

```ruby
/a*/.examples(max_repeater_variance: 5)
  #=> [''. 'a', 'aa', 'aaa', 'aaaa' 'aaaaa']
/[F-X]/.examples(max_group_results: 10)
  #=> ['F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O']
/.*/.random_example(max_repeater_variance: 50)
  #=> "A very unlikely result!"
```

_**WARNING**: Choosing huge numbers for `Regexp#examples` and/or a sufficiently "complex" regex, could easily cause your system to freeze!_

For example, if you try to generate a list of _all_ 5-letter words: `/\w{5}/.examples(max_group_results: 999)`, then since there are actually `63` "word" characters (upper/lower case letters, numbers and "\_"), this will try to generate `63**5 #=> 992436543` (almost 1 _billion_) examples!

In other words, think twice before playing around with this config!

A more sensible use case might be, for example, to generate all 1-4 digit strings:

`/\d{1,4}/.examples(max_repeater_variance: 3, max_group_results: 10)`

Due to code optimisation, this is not something you need to worry about (much) for `Regexp#random_example`. For instance, the following takes no more than ~ 1 second on my machine:

`/.*\w+\d{100}/.random_example(max_repeater_variance: 1000)`

## TODO

* Performance improvements:
  * Use of lambdas/something (in [constants.rb](lib/regexp-examples/constants.rb)) to improve the library load time. See the pending pull request.
  * (Maybe?) add a `max_examples` configuration option and use lazy evaluation, to ensure the method never "freezes".

## Contributing

1. Fork it ( https://github.com/[my-github-username]/regexp-examples/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
6. Don't forget to add tests!!
