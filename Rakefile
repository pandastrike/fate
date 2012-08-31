$:.unshift "../starter/lib"
require "starter/tasks/gems"
require "starter/tasks/git"

task "build" => %w[ gem:build ]
task "release" => %w[ build gem:push tag ]

