Dir[File.dirname(__FILE__) + '/regexp-examples/*.rb'].each {|file| require file }

# TODO: DEBUG. DELETE THIS.
#require 'pry'
#RegexpExamples::show(/a*/)
#RegexpExamples::show(/a+/)
#RegexpExamples::show(/a?/)
#RegexpExamples::show(/a{1,2}/)
#RegexpExamples::show(/a{1,}/)
#RegexpExamples::show(/https?:\/\/(www\.)?google\.com/) # AWWW YEEEAHH!
#RegexpExamples::show(/a|b/)
#RegexpExamples::show(/(a)/)
#RegexpExamples::show(/((a))\1\2/)
#
#binding.pry
