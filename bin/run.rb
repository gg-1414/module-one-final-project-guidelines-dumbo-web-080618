require_relative '../config/environment'

puts `clear`
# system 'while :; do afplay ./sound/test.mp3; done'

User.new.welcome
