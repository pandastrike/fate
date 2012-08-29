Gem::Specification.new do |s|
  s.name = "fate"
  s.version = "0.2.2"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/automatthew/fate"
  s.summary = "Tool for running and interacting with a multi-process service"

  s.files = %w[
    bin/fate
    LICENSE
    lib/fate.rb
    lib/hash_tree.rb
    lib/fate/console.rb
  ]
  s.require_path = "lib"
  s.executables = "fate"

  s.add_dependency("consolize", ">=0.2.0")
  s.add_dependency("open4", ">=1.3.0")
  s.add_dependency("term-ansicolor", ">=1.0.0")
end

