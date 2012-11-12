#!/usr/bin/env ruby


unless startup_delay = ARGV[0]
  raise "Must supply startup delay as first argument"
end

startup_delay = startup_delay.to_i

sleep(startup_delay)

puts "Started up after delay: #{startup_delay}"
$stdout.flush

loop do
  sleep 1
end
