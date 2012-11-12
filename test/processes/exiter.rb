#!/usr/bin/env ruby

delay, status = ARGV

if delay
  delay = delay.to_i
else
  delay = 2
end

if status
  status = status.to_i
else
  status = 0
end

sleep(delay)
exit(status)
