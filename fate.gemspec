Gem::Specification.new do |s|
  s.name = "fate"
  s.version = "0.2.6"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/automatthew/fate"
  s.summary = "Tool for running and interacting with a multi-process service"

  s.files = %w[
    bin/fate
    LICENSE
    README.md
    lib/fate.rb
    lib/fate/repl.rb
    lib/fate/formatter.rb
    lib/fate/manager.rb
  ]
  s.require_path = "lib"
  s.executables = "fate"

  s.add_dependency("harp", ">=0.2.4")
  s.add_dependency("open4", ">=1.3.0")
  s.add_dependency("squeeze", ">=0.2.0")
  s.add_dependency("term-ansicolor", ">=1.0.0")
end

