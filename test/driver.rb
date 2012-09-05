#!/usr/bin/env ruby
counter = 0

string = ARGV[0]
loop do
  puts "Test #{string} #{counter += 1}"
  STDOUT.flush
  sleep (rand * 3)
end
