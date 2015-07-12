require 'pstore'
require_relative '../lib/regexp-examples/unicode_char_ranges'
# A script to generate lists of all unicode characters
# that match all named group/character properties regexps.
# For use in e.g. /\p{Arabic}/.examples

# To (re-)generate this list, simply run this file!
# > ruby scripts/unicode_lister.rb

# Taken from ruby documentation:
# http://ruby-doc.org//core-2.2.0/Regexp.html#class-Regexp-label-Character+Properties
NamedGroups = %w(
  Alnum
  Alpha
  Blank
  Cntrl
  Digit
  Graph
  Lower
  Print
  Punct
  Space
  Upper
  XDigit
  Word
  ASCII
  Any
  Assigned

  L
  Ll
  Lm
  Lo
  Lt
  Lu
  M
  Mn
  Mc
  Me
  N
  Nd
  Nl
  No
  P
  Pc
  Pd
  Ps
  Pe
  Pi
  Pf
  Po
  S
  Sm
  Sc
  Sk
  So
  Z
  Zs
  Zl
  Zp
  C
  Cc
  Cf
  Cn
  Co
  Cs

  Arabic
  Armenian
  Balinese
  Bengali
  Bopomofo
  Braille
  Buginese
  Buhid
  Canadian_Aboriginal
  Carian
  Cham
  Cherokee
  Common
  Coptic
  Cuneiform
  Cypriot
  Cyrillic
  Deseret
  Devanagari
  Ethiopic
  Georgian
  Glagolitic
  Gothic
  Greek
  Gujarati
  Gurmukhi
  Han
  Hangul
  Hanunoo
  Hebrew
  Hiragana
  Inherited
  Kannada
  Katakana
  Kayah_Li
  Kharoshthi
  Khmer
  Lao
  Latin
  Lepcha
  Limbu
  Linear_B
  Lycian
  Lydian
  Malayalam
  Mongolian
  Myanmar
  New_Tai_Lue
  Nko
  Ogham
  Ol_Chiki
  Old_Italic
  Old_Persian
  Oriya
  Osmanya
  Phags_Pa
  Phoenician
  Rejang
  Runic
  Saurashtra
  Shavian
  Sinhala
  Sundanese
  Syloti_Nagri
  Syriac
  Tagalog
  Tagbanwa
  Tai_Le
  Tamil
  Telugu
  Thaana
  Thai
  Tibetan
  Tifinagh
  Ugaritic
  Vai
  Yi
)

# Note: For the range 55296..57343, these are reserved values that are not legal
# unicode characters.
# I.e. a character encoding-related exception gets raised when you do:
# `/regex/ =~ eval("?\\u{#{x.to_s(16)}}")`
# TODO: Add a link to somewhere that explains this better.

# Example input: [1, 2, 3, 4, 6, 7, 12, 14] (Array)
# Example output: "1..4, 6..7, 12, 14" (String)
def calculate_ranges(matching_codes)
  return "" if matching_codes.empty?
  first = matching_codes.shift
  matching_codes.inject([first..first]) do |r,x|
    if r.last.last.succ != x
      r << (x..x) # Start new range
    else
      r[0..-2] << (r.last.first..x) # Update last range
    end
  end
    .map { |range| range.size == 1 ? range.first : range}
end

count = 0
filename = "db/#{RegexpExamples::UnicodeCharRanges::STORE_FILENAME}"
store = PStore.new(filename)
store.transaction do
  NamedGroups.each do |name|
    count += 1
    # Original method, for only generating first 128 matches:
    #matching_codes = (0..55295).lazy.select { |x| /\p{#{name}}/ =~ eval("?\\u{#{x.to_s(16)}}") }.first(128)
    # Since this data is now being compressed and saved in a PStore, let's just generate everything!
    matching_codes = [(0..55295), (57344..65535)].map(&:to_a).flatten.select { |x| /\p{#{name}}/ =~ eval("?\\u{#{x.to_s(16)}}") }
    store[name.downcase] = calculate_ranges(matching_codes)
    puts "(#{count}/#{NamedGroups.length}) Finished property: #{name}"
  end
  puts "*"*50
  puts "Finished! Result stored in: #{filename}"
end

