Gem::Specification.new do |s|
  s.name = "spawn_control"
  s.version = "0.2.0"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/automatthew/spawn_control"
  s.summary = "Tool for running and interacting with a multi-process service"

  s.files = %w[
    bin/spawn_control
    LICENSE
    lib/spawn_control.rb
    lib/hash_tree.rb
    lib/spawn_control/console.rb
  ]
  s.require_path = "lib"
  s.executables = "spawn_control"

  s.add_dependency("consolize", ">=0.2.0")
  s.add_dependency("open4", ">=1.3.0")
  s.add_dependency("term-ansicolor", ">=1.0.0")
end

